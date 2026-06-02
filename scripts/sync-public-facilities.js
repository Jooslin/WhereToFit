const crypto = require("node:crypto");

const API_URL =
  "https://api.data.go.kr/openapi/tn_pubr_public_pblfclt_opn_info_api";
const TABLE_NAME = "public_facilities";
const METADATA_TABLE_NAME = "public_facility_sync_metadata";
const METADATA_ID = "public_facilities";
const PAGE_SIZE = 1000;
const UPSERT_BATCH_SIZE = 500;
const DELETE_BATCH_SIZE = 100;

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

async function main() {
  const result = await syncPublicFacilities();
  console.log(JSON.stringify(result, null, 2));
}

async function syncPublicFacilities() {
  const startedAt = new Date();
  const rows = await fetchAllRows();
  console.log(`Fetched ${rows.length} rows from data.go.kr.`);

  const nextRows = rows.map(toTableRow);
  const nextById = new Map(nextRows.map((row) => [row.id, row]));
  console.log(`Prepared ${nextById.size} Supabase rows.`);

  const existingById = await fetchExistingRows();
  console.log(`Loaded ${existingById.size} existing Supabase rows.`);

  const rowsToUpsert = [];
  const idsToDelete = [];
  let created = 0;
  let updated = 0;
  let unchanged = 0;

  for (const [id, next] of nextById) {
    const existing = existingById.get(id);

    if (!existing) {
      rowsToUpsert.push(next);
      created += 1;
      continue;
    }

    if (existing.source_hash !== next.source_hash) {
      rowsToUpsert.push(next);
      updated += 1;
      continue;
    }

    unchanged += 1;
  }

  for (const id of existingById.keys()) {
    if (!nextById.has(id)) {
      idsToDelete.push(id);
    }
  }

  await upsertRows(rowsToUpsert);
  await deleteRows(idsToDelete);
  await upsertMetadata({
    source: API_URL,
    started_at: startedAt.toISOString(),
    finished_at: new Date().toISOString(),
    total: nextById.size,
    created,
    updated,
    unchanged,
    deleted: idsToDelete.length,
  });

  return {
    table: TABLE_NAME,
    total: nextById.size,
    created,
    updated,
    unchanged,
    deleted: idsToDelete.length,
  };
}

async function fetchAllRows() {
  const firstPage = await fetchPage(1);
  const totalCount = Number(firstPage.totalCount ?? firstPage.totalcount ?? 0);
  const rows = [...firstPage.items];
  const totalPages = Math.ceil(totalCount / PAGE_SIZE);

  console.log(
    `Fetched page 1/${totalPages || 1}. totalCount=${totalCount}, rows=${rows.length}.`,
  );

  for (let pageNo = 2; pageNo <= totalPages; pageNo += 1) {
    const page = await fetchPage(pageNo);
    rows.push(...page.items);
    console.log(`Fetched page ${pageNo}/${totalPages}. rows=${rows.length}.`);
  }

  return rows;
}

async function fetchPage(pageNo) {
  const url = new URL(API_URL);
  url.searchParams.set("pageNo", String(pageNo));
  url.searchParams.set("numOfRows", String(PAGE_SIZE));
  url.searchParams.set("type", "json");

  const response = await fetch(withServiceKey(url));
  const text = await response.text();

  if (!response.ok) {
    throw new Error(`data.go.kr request failed: ${response.status} ${text}`);
  }

  return parsePagePayload(text);
}

function parsePagePayload(text) {
  const payload = JSON.parse(text);
  const body = payload.response?.body ?? payload.body;
  const header = payload.response?.header ?? payload.header;

  if (header?.resultCode && header.resultCode !== "00") {
    throw new Error(
      `data.go.kr returned ${header.resultCode}: ${header.resultMsg ?? "unknown error"}`,
    );
  }

  return {
    totalCount: body?.totalCount,
    items: normalizeItems(body?.items),
  };
}

async function fetchExistingRows() {
  const rows = [];
  const pageSize = 1000;

  for (let from = 0; ; from += pageSize) {
    const to = from + pageSize - 1;
    const data = await supabaseFetch(
      `${TABLE_NAME}?select=id,source_hash&order=id.asc`,
      {
        headers: {
          Range: `${from}-${to}`,
        },
      },
    );

    rows.push(...data);

    if (data.length < pageSize) {
      break;
    }
  }

  return new Map(rows.map((row) => [row.id, row]));
}

async function upsertRows(rows) {
  for (let index = 0; index < rows.length; index += UPSERT_BATCH_SIZE) {
    const chunk = rows.slice(index, index + UPSERT_BATCH_SIZE);
    await supabaseFetch(`${TABLE_NAME}?on_conflict=id`, {
      method: "POST",
      headers: {
        Prefer: "resolution=merge-duplicates",
      },
      body: JSON.stringify(chunk),
    });

    console.log(`Upserted ${Math.min(index + chunk.length, rows.length)}/${rows.length}.`);
  }
}

async function deleteRows(ids) {
  for (let index = 0; index < ids.length; index += DELETE_BATCH_SIZE) {
    const chunk = ids.slice(index, index + DELETE_BATCH_SIZE);
    await supabaseFetch(`${TABLE_NAME}?id=in.(${chunk.join(",")})`, {
      method: "DELETE",
    });

    console.log(`Deleted ${Math.min(index + chunk.length, ids.length)}/${ids.length}.`);
  }
}

async function upsertMetadata(metadata) {
  await supabaseFetch(`${METADATA_TABLE_NAME}?on_conflict=id`, {
    method: "POST",
    headers: {
      Prefer: "resolution=merge-duplicates",
    },
    body: JSON.stringify({
      id: METADATA_ID,
      ...metadata,
    }),
  });
}

async function supabaseFetch(path, options = {}) {
  const baseURL = requiredEnv("SUPABASE_URL").replace(/\/+$/, "");
  const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const headers = {
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    "Content-Type": "application/json",
    Accept: "application/json",
    ...(options.headers ?? {}),
  };

  const response = await fetch(`${baseURL}/rest/v1/${path}`, {
    ...options,
    headers,
  });
  const text = await response.text();

  if (!response.ok) {
    throw new Error(`Supabase request failed: ${response.status} ${text}`);
  }

  if (!text) {
    return [];
  }

  return JSON.parse(text);
}

function toTableRow(row) {
  const normalized = normalizeRow(row);
  const sourceKey = [
    pickFirst(normalized, ["insttCode", "instt_code"]),
    normalized.openFcltyNm,
    normalized.openLcNm,
    normalized.rdnmadr,
    normalized.lnmadr,
    normalized.latitude,
  ]
    .filter(Boolean)
    .join("|");
  const id = hash(sourceKey || JSON.stringify(normalized));
  const sourceHash = hash(JSON.stringify(normalized));

  return {
    id,
    source_key: sourceKey,
    source_hash: sourceHash,
    facility_name: nullable(normalized.openFcltyNm),
    location_name: nullable(normalized.openLcNm),
    facility_type: nullable(normalized.openFcltyType),
    closed_days: nullable(normalized.rstde),
    weekday_open_time: nullable(normalized.weekdayOperOpenHhmm),
    weekday_close_time: nullable(normalized.weekdayOperColseHhmm),
    weekend_open_time: nullable(normalized.wkendOperOpenHhmm),
    weekend_close_time: nullable(normalized.wkendOperCloseHhmm),
    is_paid: nullable(normalized.pchrgUseYn),
    usage_standard_time: nullable(normalized.useStdrTime),
    rental_fee: nullable(normalized.rntfee),
    excess_use_unit_time: nullable(normalized.excessUseUnitTime),
    excess_rental_fee: nullable(normalized.excessRntfee),
    capacity: nullable(normalized.aceptncPosblCo),
    area: nullable(normalized.ar),
    extra_facility_info: nullable(normalized.etcFclty),
    application_method_type: nullable(normalized.sbscrptnMthSe),
    facility_image: nullable(normalized.fcltyPicInfo),
    road_address: nullable(normalized.rdnmadr),
    lot_number_address: nullable(normalized.lnmadr),
    latitude: nullable(normalized.latitude),
    longitude: nullable(normalized.longitude),
    institution: nullable(normalized.institutionNm),
    charge_department: nullable(normalized.chrgDeptNm),
    phone_number: nullable(normalized.phoneNumber),
    homepage_url: nullable(normalized.homepageUrl),
    reference_date: nullable(normalized.referenceDate),
    institution_code: nullable(pickFirst(normalized, ["insttCode", "instt_code"])),
    provider_institution: nullable(pickFirst(normalized, ["insttNm", "instt_nm"])),
    raw_data: normalized,
    synced_at: new Date().toISOString(),
  };
}

function nullable(value) {
  return value === undefined ? null : value;
}

function normalizeRow(row) {
  const normalized = {};

  for (const [key, value] of Object.entries(row)) {
    if (value === null || value === undefined) {
      continue;
    }

    const trimmed = String(value).trim();

    if (trimmed) {
      normalized[key] = trimmed;
    }
  }

  setNumber(normalized, "latitude");
  setNumber(normalized, "longitude");

  return normalized;
}

function setNumber(object, key) {
  if (!object[key]) {
    return;
  }

  const text = String(object[key]).replaceAll(",", "").trim();

  if (!/^-?\d+(\.\d+)?$/.test(text)) {
    object[key] = null;
    return;
  }

  const value = Number(text);

  if (Number.isFinite(value)) {
    object[key] = value;
  } else {
    object[key] = null;
  }
}

function normalizeItems(items) {
  if (!items) {
    return [];
  }

  if (Array.isArray(items)) {
    return items;
  }

  if (typeof items === "object" && items !== null && "item" in items) {
    const item = items.item;

    if (Array.isArray(item)) {
      return item;
    }

    if (item) {
      return [item];
    }
  }

  return [];
}

function withServiceKey(url) {
  const separator = url.search ? "&" : "?";
  const serviceKey = dataGoServiceKey();
  const key = serviceKey.includes("%")
    ? serviceKey
    : encodeURIComponent(serviceKey);

  return `${url.toString()}${separator}serviceKey=${key}`;
}

function dataGoServiceKey() {
  return requiredEnv("DATA_GO_KR_SERVICE_KEY");
}

function requiredEnv(name) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`${name} is required.`);
  }

  return value;
}

function sanitizeSecret(value) {
  return value.replace(/serviceKey=[^&\s)]+/g, "serviceKey=[redacted]");
}

function pickFirst(object, keys) {
  for (const key of keys) {
    if (object[key]) {
      return object[key];
    }
  }

  return undefined;
}

function hash(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}
