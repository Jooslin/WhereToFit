import crypto from "node:crypto";
import admin from "firebase-admin";

const API_URL =
  "https://api.data.go.kr/openapi/tn_pubr_public_pblfclt_opn_info_api";
const COLLECTION_NAME = "publicFacilities";
const METADATA_COLLECTION_NAME = "syncMetadata";
const METADATA_DOCUMENT_ID = "publicFacilities";
const PAGE_SIZE = 1000;
const MAX_BATCH_WRITES = 450;

const serviceKey = process.env.DATA_GO_KR_SERVICE_KEY;
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceKey) {
  throw new Error("DATA_GO_KR_SERVICE_KEY is required.");
}

if (!serviceAccountJson) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT is required.");
}

const serviceAccount = JSON.parse(serviceAccountJson);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function main() {
  const startedAt = new Date();
  const rows = await fetchAllRows();
  const nextDocuments = new Map(rows.map((row) => toDocumentEntry(row)));
  const existingDocuments = await fetchExistingDocuments();

  let created = 0;
  let updated = 0;
  let unchanged = 0;
  let deleted = 0;

  const writer = new BatchWriter(db);

  for (const [id, next] of nextDocuments) {
    const existing = existingDocuments.get(id);

    if (!existing) {
      writer.set(db.collection(COLLECTION_NAME).doc(id), next.data);
      created += 1;
      continue;
    }

    if (existing.sourceHash !== next.data.sourceHash) {
      writer.set(db.collection(COLLECTION_NAME).doc(id), next.data, { merge: false });
      updated += 1;
      continue;
    }

    unchanged += 1;
  }

  for (const [id] of existingDocuments) {
    if (!nextDocuments.has(id)) {
      writer.delete(db.collection(COLLECTION_NAME).doc(id));
      deleted += 1;
    }
  }

  writer.set(
    db.collection(METADATA_COLLECTION_NAME).doc(METADATA_DOCUMENT_ID),
    {
      source: API_URL,
      startedAt: admin.firestore.Timestamp.fromDate(startedAt),
      finishedAt: admin.firestore.FieldValue.serverTimestamp(),
      total: nextDocuments.size,
      created,
      updated,
      unchanged,
      deleted,
    },
    { merge: true },
  );

  await writer.flush();

  console.log(
    JSON.stringify(
      {
        collection: COLLECTION_NAME,
        total: nextDocuments.size,
        created,
        updated,
        unchanged,
        deleted,
      },
      null,
      2,
    ),
  );
}

async function fetchAllRows() {
  const firstPage = await fetchPage(1);
  const totalCount = Number(firstPage.totalCount ?? firstPage.totalcount ?? 0);
  const rows = [...firstPage.items];
  const totalPages = Math.ceil(totalCount / PAGE_SIZE);

  for (let pageNo = 2; pageNo <= totalPages; pageNo += 1) {
    const page = await fetchPage(pageNo);
    rows.push(...page.items);
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

function withServiceKey(url) {
  const separator = url.search ? "&" : "?";
  const key = serviceKey.includes("%") ? serviceKey : encodeURIComponent(serviceKey);

  return `${url.toString()}${separator}serviceKey=${key}`;
}

function normalizeItems(items) {
  if (!items) {
    return [];
  }

  if (Array.isArray(items)) {
    return items;
  }

  if (Array.isArray(items.item)) {
    return items.item;
  }

  if (items.item) {
    return [items.item];
  }

  return [];
}

async function fetchExistingDocuments() {
  const snapshot = await db.collection(COLLECTION_NAME).get();
  const documents = new Map();

  for (const doc of snapshot.docs) {
    documents.set(doc.id, {
      sourceHash: doc.get("sourceHash"),
    });
  }

  return documents;
}

function toDocumentEntry(row) {
  const normalized = normalizeRow(row);
  const sourceKey = [
    pickFirst(normalized, ["instt_code", "insttCode", "mngInsttNm", "insttNm"]),
    pickFirst(normalized, ["opnFcltyNm", "openFcltyNm", "fcltyNm"]),
    pickFirst(normalized, ["opnPlcNm", "openLcNm", "plcNm"]),
    pickFirst(normalized, ["rdnmadr", "roadNmAddr"]),
    pickFirst(normalized, ["lnmadr", "lotnoAddr"]),
    pickFirst(normalized, ["latitude", "longitude"]),
  ]
    .filter(Boolean)
    .join("|");
  const id = hash(sourceKey || JSON.stringify(normalized));
  const sourceHash = hash(JSON.stringify(normalized));

  return [
    id,
    {
      data: {
        ...normalized,
        sourceKey,
        sourceHash,
        syncedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
  ];
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
  setNumber(normalized, "aceptncPosblCo");
  setNumber(normalized, "ar");

  if (
    typeof normalized.latitude === "number" &&
    typeof normalized.longitude === "number"
  ) {
    normalized.location = new admin.firestore.GeoPoint(
      normalized.latitude,
      normalized.longitude,
    );
  }

  return normalized;
}

function setNumber(object, key) {
  if (!object[key]) {
    return;
  }

  const value = Number(String(object[key]).replaceAll(",", ""));

  if (Number.isFinite(value)) {
    object[key] = value;
  }
}

function pickFirst(object, keys) {
  for (const key of keys) {
    if (object[key]) {
      return object[key];
    }
  }

  return "";
}

function hash(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

class BatchWriter {
  constructor(firestore) {
    this.firestore = firestore;
    this.batch = firestore.batch();
    this.pendingWrites = 0;
    this.commits = [];
  }

  set(ref, data, options) {
    if (options) {
      this.batch.set(ref, data, options);
    } else {
      this.batch.set(ref, data);
    }

    this.queueCommit();
  }

  delete(ref) {
    this.batch.delete(ref);
    this.queueCommit();
  }

  queueCommit() {
    this.pendingWrites += 1;

    if (this.pendingWrites >= MAX_BATCH_WRITES) {
      this.commits.push(this.batch.commit());
      this.batch = this.firestore.batch();
      this.pendingWrites = 0;
    }
  }

  async flush() {
    if (this.pendingWrites > 0) {
      this.commits.push(this.batch.commit());
    }

    await Promise.all(this.commits);
  }
}
