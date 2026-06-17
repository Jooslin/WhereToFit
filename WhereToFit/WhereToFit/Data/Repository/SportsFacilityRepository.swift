//
//  SportsFacilityRepository.swift
//  WhereToFit
//
//  Created by 김주희 on 6/4/26.
//

import Foundation
import RxSwift

/// Supabase에서 받은 시설/프로그램 데이터를 지도 화면에서 쓰는 `FitnessFacility` 형태로 변환하는 Repository
/// 지도 마커는 시설 기준, 하단 모달은 프로그램 기준으로 보여주기 위해 두 종류의 데이터를 같은 도메인 모델로 맞춥니다.
final class SportsFacilityRepository: FacilityRepositoryProtocol {
    private let sportsRepository: SportsRepositoryProtocol
    private let pageSize: Int
    private let maximumConcurrentFacilityPageRequests = 4
    private var cachedFacilityDataSet: FitnessFacilityDataSet?

    init(
        sportsRepository: SportsRepositoryProtocol = SportsRepository(),
        pageSize: Int = 1_000
    ) {
        self.sportsRepository = sportsRepository
        self.pageSize = pageSize
    }

    func fetchFacilities() -> Single<FitnessFacilityDataSet> {
        // 지도 첫 진입에서는 시설 마커만 먼저 만들고, 프로그램은 보이는 시설 범위에 맞춰 따로 불러오기
        if let cachedFacilityDataSet {
            return .just(cachedFacilityDataSet)
        }

        return fetchAllFacilityPages()
        .map { facilities in
            let markerFacilities = facilities.compactMap(Self.makeFitnessFacility)

            return FitnessFacilityDataSet(
                markerFacilities: markerFacilities,
                programFacilities: []
            )
        }
        .do(onSuccess: { [weak self] dataSet in
            self?.cachedFacilityDataSet = dataSet
        })
    }

    func fetchPrograms(for facilities: [FitnessFacility]) -> Single<[FitnessFacility]> {
        // class_information.public_facility_id로 시설과 프로그램을 매핑
        // 문자열 매칭보다 안정적이고, 현재 지도 영역의 시설에 대해서만 요청할 수 있어 초기 로딩을 줄일 수 있음
        let facilitiesByID = Dictionary(
            uniqueKeysWithValues: facilities.compactMap { facility in
                facility.sourceFacilityID.map { ($0, facility) }
            }
        )
        let facilityIDs = Array(facilitiesByID.keys)

        guard facilityIDs.isEmpty == false else {
            return .just([])
        }

        let programPageSingles = facilityIDs.chunked(into: 40).map { facilityIDChunk in
            fetchAllProgramPages(
                facilityIDs: facilityIDChunk,
                offset: 0,
                accumulated: []
            )
        }

        return Single.zip(programPageSingles)
            .map { programGroups in
                programGroups
                    .flatMap { $0 }
                    .compactMap { program in
                        guard let facilityID = program.publicFacilityID,
                              let facility = facilitiesByID[facilityID] else {
                            return nil
                        }

                        return Self.makeFitnessFacility(from: program, facility: facility)
                    }
            }
    }

    private func fetchAllFacilityPages() -> Single<[Facility]> {
        sportsRepository.fetchFacilities(
            limit: pageSize,
            offset: 0,
            order: .ascending,
            includesTotalCount: true
        )
        .flatMap { [self] page -> Single<[Facility]> in
            guard let totalCount = page.totalCount else {
                // count를 못 받은 경우에는 nextOffset을 따라가며 안전하게 모든 페이지를 이어받습니다.
                guard let nextOffset = page.nextOffset else {
                    return .just(page.items)
                }

                return fetchFacilityPagesSequentially(
                    offset: nextOffset,
                    accumulated: page.items
                )
            }

            // totalCount가 있으면 페이지 offset을 미리 계산해 몇 개씩 병렬 요청합니다.
            let remainingOffsets = Array(stride(from: pageSize, to: totalCount, by: pageSize))
            return fetchFacilityPagesConcurrently(
                offsets: remainingOffsets,
                accumulated: page.items
            )
        }
    }

    private func fetchFacilityPagesConcurrently(
        offsets: [Int],
        accumulated: [Facility]
    ) -> Single<[Facility]> {
        guard offsets.isEmpty == false else {
            return .just(accumulated)
        }

        let batchOffsets = Array(offsets.prefix(maximumConcurrentFacilityPageRequests))
        let remainingOffsets = Array(offsets.dropFirst(maximumConcurrentFacilityPageRequests))
        let pageSingles = batchOffsets.map { offset in
            sportsRepository.fetchFacilities(
                limit: pageSize,
                offset: offset,
                order: .ascending
            )
            .map(\.items)
        }

        return Single.zip(pageSingles)
            .flatMap { [self] pageGroups in
                fetchFacilityPagesConcurrently(
                    offsets: remainingOffsets,
                    accumulated: accumulated + pageGroups.flatMap { $0 }
                )
            }
    }

    private func fetchFacilityPagesSequentially(
        offset: Int,
        accumulated: [Facility]
    ) -> Single<[Facility]> {
        sportsRepository.fetchFacilities(
            limit: pageSize,
            offset: offset,
            order: .ascending
        )
        .flatMap { [self] page -> Single<[Facility]> in
            let facilities = accumulated + page.items

            guard let nextOffset = page.nextOffset else {
                return .just(facilities)
            }

            return fetchFacilityPagesSequentially(
                offset: nextOffset,
                accumulated: facilities
            )
        }
    }

    private func fetchAllProgramPages(
        facilityIDs: [String],
        offset: Int,
        accumulated: [Program]
    ) -> Single<[Program]> {
        sportsRepository.fetchPrograms(
            facilityIDs: facilityIDs,
            limit: pageSize,
            offset: offset,
            order: .ascending
        )
        .flatMap { [self] page -> Single<[Program]> in
            let programs = accumulated + page.items

            guard let nextOffset = page.nextOffset else {
                return .just(programs)
            }

            return fetchAllProgramPages(
                facilityIDs: facilityIDs,
                offset: nextOffset,
                accumulated: programs
            )
        }
    }
}

fileprivate extension SportsFacilityRepository {
    nonisolated static func makeFitnessFacility(
        from program: Program,
        facility: FitnessFacility
    ) -> FitnessFacility {
        // 프로그램 셀도 시설 상세로 이동할 수 있어야 하므로 시설의 좌표/주소/편의시설 정보를 함께 보존합니다.
        let programID = program.id.map(String.init) ?? normalizedMatchText([
            program.facilityName,
            program.className,
            program.startTime,
            program.endTime
        ])
        let name = nonEmptyTrimmed(program.className)
            ?? nonEmptyTrimmed(program.sport)
            ?? facility.name
        let category = parseCategory(from: [
            program.sport,
            program.className,
            program.classDescription,
            facility.name,
            facility.facilityType
        ])
        let price = max(0, program.priceAmount ?? 0)
        let availableTimeRange = TimeRange(
            startHour: parseHour(program.startTime) ?? facility.availableTimeRange.startHour,
            endHour: parseHour(program.endTime) ?? facility.availableTimeRange.endHour
        )
        let homepageURL = makeWebURL(program.homepageURL) ?? facility.homepageURL
        let reservationURL = homepageURL ?? facility.reservationURL
        let reservationMethods = program.reservationMethods
        let applicationMethodText = reservationMethods.isEmpty
            ? facility.applicationMethodText
            : reservationMethods.map(\.title).joined(separator: ", ")
        let description = [
            program.classDescription,
            program.priceNote.flatMap(nonEmptyTrimmed).map { "가격 안내: \($0)" },
            program.facilityLocation.flatMap(nonEmptyTrimmed),
            facility.description
        ]
        .compactMap { $0 }
        .filter { $0.isEmpty == false }
        .joined(separator: "\n")

        return FitnessFacility(
            id: "program-\(programID)-facility-\(facility.sourceFacilityID ?? facility.id)",
            name: name,
            address: facility.address,
            phoneNumber: program.phoneNumber ?? facility.phoneNumber,
            category: category,
            coordinate: facility.coordinate,
            distanceInMeters: facility.distanceInMeters,
            price: price,
            rawPriceText: nonEmptyTrimmed(program.rawPriceText),
            availableDays: parseProgramDays(program.days),
            availableTimeRange: availableTimeRange,
            imageURL: facility.imageURL,
            isFavorite: false,
            requiresReservation: reservationMethods.isEmpty == false || facility.requiresReservation,
            matchingRate: makeMatchingRate(price: price, category: category),
            reservationURL: reservationURL,
            homepageURL: homepageURL,
            description: description.isEmpty ? facility.description : description,
            locationName: facility.locationName ?? program.facilityName,
            facilityType: program.sport ?? facility.facilityType,
            operatingHoursText: makeProgramOperatingHoursText(program: program, fallbackText: facility.operatingHoursText),
            applicationMethodText: applicationMethodText,
            introduction: facility.introduction,
            amenities: facility.amenities,
            parkingInfo: facility.parkingInfo,
            sourceKind: .program,
            sourceFacilityID: facility.sourceFacilityID ?? facility.id,
            sourceProgramID: program.id
        )
    }

    nonisolated static func makeFitnessFacility(from facility: Facility) -> FitnessFacility? {
        // 좌표가 없는 시설은 지도 마커로 표시할 수 없으므로 제외합니다.
        guard let latitude = facility.latitude,
              let longitude = facility.longitude else {
            return nil
        }

        let id = facility.id ?? "\(latitude)-\(longitude)-\(facility.facilityName ?? "")"
        let name = facility.facilityName ?? facility.locationName ?? "이름 없는 시설"
        let address = facility.roadAddress ?? facility.lotNumberAddress ?? "주소 정보 없음"
        let price = parsePrice(facility.rentalFee)
        let category = parseCategory(from: [
            facility.facilityName,
            facility.locationName,
            facility.facilityType,
            facility.extraFacilityInfo
        ])
        let availableDays = parseAvailableDays(closeDays: facility.closeDays)
        let availableTimeRange = parseTimeRange(
            openTime: facility.weekdayOpenTime ?? facility.weekendOpenTime,
            closeTime: facility.weekdayCloseTime ?? facility.weekendCloseTime
        )
        let homepageURL = makeWebURL(facility.homepageUrl)
        let reservationURL = homepageURL ?? makeReservationURL(homepageURL: nil, fallbackKeyword: name)

        return FitnessFacility(
            id: id,
            name: name,
            address: address,
            phoneNumber: facility.phoneNumber ?? "전화번호 정보 없음",
            category: category,
            coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            distanceInMeters: distanceFromDefaultLocation(latitude: latitude, longitude: longitude),
            price: price,
            priceDisplayText: makePriceDisplayText(facility.rentalFee),
            rawPriceText: nonEmptyTrimmed(facility.rentalFee),
            availableDays: availableDays,
            availableTimeRange: availableTimeRange,
            imageURL: URL(string: facility.facilityImage ?? ""),
            isFavorite: false,
            requiresReservation: facility.reservationMethods.isEmpty == false,
            matchingRate: makeMatchingRate(price: price, category: category),
            reservationURL: reservationURL,
            homepageURL: homepageURL,
            description: makeDescription(from: facility),
            locationName: facility.locationName,
            facilityType: facility.facilityType,
            operatingHoursText: makeOperatingHoursText(from: facility),
            applicationMethodText: makeApplicationMethodText(from: facility),
            introduction: makeIntroduction(from: facility),
            amenities: makeAmenities(from: facility),
            parkingInfo: makeParkingInfo(from: facility),
            sourceKind: .facility,
            sourceFacilityID: id
        )
    }

    nonisolated static func parseCategory(from values: [String?]) -> FacilityCategory {
        let text = values.compactMap { $0 }.joined(separator: " ")

        func contains(_ keywords: String...) -> Bool {
            keywords.contains { keyword in
                text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }

        // 구체적인 종목을 먼저 검사해야 "파워요가"가 일반 "요가"로 먼저 분류되는 일을 막을 수 있습니다.
        if contains("헬스PT", "헬스 PT") { return .healthPT }
        if contains("보디빌딩", "바디빌딩") { return .bodybuilding }
        if contains("헬스", "체력단련", "웨이트", "근력") { return .gym }
        if contains("GX") { return .gx }
        if contains("TRX") { return .trx }
        if contains("서킷트레이닝", "서킷 트레이닝") { return .circuitTraining }
        if contains("스피닝바이크", "스피닝 바이크", "스피닝") { return .spinningBike }
        if contains("다이어트로빅") { return .dietRobics }
        if contains("시니어로빅") { return .seniorRobics }
        if contains("에어로빅") { return .aerobics }
        if contains("태보") { return .taebo }
        if contains("점핑다이어트", "점핑 다이어트") { return .jumpingDiet }
        if contains("점핑트램폴린", "점핑 트램폴린") { return .jumpingTrampoline }
        if contains("핏밸런스", "핏 밸런스") { return .fitBalance }
        if contains("여성순환운동", "여성 순환운동", "여성순환 운동") { return .womensCircuitExercise }
        if contains("파워요가", "파워 요가") { return .powerYoga }
        if contains("필라테스") { return .pilates }
        if contains("SNPE") { return .snpe }
        if contains("요가") { return .yoga }
        if contains("국선도") { return .kuksundo }
        if contains("국학기공") { return .koreanQigong }
        if contains("태극권") { return .taiChi }
        if contains("생활체조") { return .lifeGymnastics }
        if contains("스트레칭") { return .stretching }
        if contains("수중보건체조", "수중 보건체조", "수중보건 체조") { return .aquaticHealthGymnastics }
        if contains("체조") { return .gymnastics }
        if contains("라인댄스", "라인 댄스") { return .lineDance }
        if contains("방송댄스", "방송 댄스") { return .broadcastDance }
        if contains("벨리댄스", "벨리 댄스") { return .bellyDance }
        if contains("스포츠댄스", "스포츠 댄스") { return .sportsDance }
        if contains("줌바댄스", "줌바 댄스") { return .zumbaDance }
        if contains("다이어트댄스", "다이어트 댄스") { return .dietDance }
        if contains("발레") { return .ballet }
        if contains("전통무용", "전통 무용") { return .traditionalDance }
        if contains("한국무용", "한국 무용") { return .koreanDance }
        if contains("댄스", "무용") { return .dance }
        if contains("생존수영", "생존 수영") { return .survivalSwimming }
        if contains("아쿠아로빅") { return .aquaRobics }
        if contains("아쿠아워킹", "아쿠아 워킹") { return .aquaWalking }
        if contains("아쿠아슬론") { return .aquathlon }
        if contains("아티스틱 스위밍", "아티스틱스위밍") { return .artisticSwimming }
        if contains("스킨스쿠버", "스킨 스쿠버") { return .scubaDiving }
        if contains("수영") { return .swimming }
        if contains("농구") { return .basketball }
        if text.contains("풋살") { return .futsal }
        if contains("축구") { return .soccer }
        if contains("야구") { return .baseball }
        if contains("배드민턴") { return .badminton }
        if contains("탁구") { return .tableTennis }
        if contains("테니스", "정구") { return .tennis }
        if contains("스쿼시") { return .squash }
        if contains("라켓볼") { return .racquetball }
        if contains("피클볼") { return .pickleball }
        if contains("파크골프", "파크 골프") { return .parkGolf }
        if contains("골프") { return .golf }
        if contains("게이트볼") { return .gateball }
        if contains("당구") { return .billiards }
        if contains("볼링") { return .bowling }
        if contains("플로어볼") { return .floorball }
        if contains("배구") { return .volleyball }
        if contains("롤러스케이트", "롤러 스케이트") { return .rollerSkating }
        if contains("스피드 스케이팅", "스피드스케이팅") { return .speedSkating }
        if contains("피겨") { return .figureSkating }
        if contains("스키") { return .skiing }
        if contains("빙상", "스케이트") { return .skating }
        if contains("검도") { return .kendo }
        if contains("복싱") { return .boxing }
        if contains("유도") { return .judo }
        if contains("태권도") { return .taekwondo }
        if contains("택견") { return .taekkyeon }
        if contains("펜싱") { return .fencing }
        if contains("국궁") { return .traditionalArchery }
        if contains("러닝") { return .running }
        if contains("달리기") { return .jogging }
        if contains("육상") { return .athletics }
        if contains("자전거", "사이클") { return .cycling }
        if contains("런바이크", "런 바이크") { return .runBike }
        if contains("철인 3종", "철인3종", "트라이애슬론") { return .triathlon }
        if contains("아동체육", "아동 체육") { return .childSports }
        if contains("유아체육", "유아 체육") { return .infantSports }
        if contains("줄넘기") { return .jumpRope }
        if contains("여성건강교실", "여성 건강교실", "여성건강 교실") { return .womensHealthClass }
        if contains("바디스킬릴리즈", "바디스킬 릴리즈", "바디스킬릴리스") { return .bodySkillRelease }
        if contains("생활체육", "생활 체육") { return .lifeSports }
        if contains("보치아") { return .boccia }
        if contains("S보드", "에스보드") { return .sBoard }
        if contains("등산") { return .hiking }
        if contains("클라이밍", "암벽") { return .climbing }
        return .multipurpose
    }

    nonisolated static func parseAvailableDays(closeDays: String?) -> [DayOfWeek] {
        guard let closeDays else {
            return DayOfWeek.allCases
        }

        let closedDays = DayOfWeek.allCases.filter { closeDays.contains(dayTitle($0)) }
        let openDays = DayOfWeek.allCases.filter { closedDays.contains($0) == false }
        return openDays.isEmpty ? DayOfWeek.allCases : openDays
    }

    nonisolated static func parseProgramDays(_ days: [String]) -> [DayOfWeek] {
        guard days.isEmpty == false else {
            return DayOfWeek.allCases
        }

        let joinedDays = days.joined(separator: " ")
        if joinedDays.contains("매일") || joinedDays.contains("상시") {
            return DayOfWeek.allCases
        }

        var parsedDays: [DayOfWeek] = []

        if joinedDays.contains("평일") {
            parsedDays.append(contentsOf: [.monday, .tuesday, .wednesday, .thursday, .friday])
        }

        if joinedDays.contains("주말") {
            parsedDays.append(contentsOf: [.saturday, .sunday])
        }

        DayOfWeek.allCases
            .filter { joinedDays.contains(dayTitle($0)) }
            .forEach { day in
                if parsedDays.contains(day) == false {
                    parsedDays.append(day)
                }
            }

        return parsedDays.isEmpty ? DayOfWeek.allCases : parsedDays
    }

    nonisolated static func dayTitle(_ day: DayOfWeek) -> String {
        switch day {
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        case .sunday: return "일"
        }
    }

    nonisolated static func parseTimeRange(openTime: String?, closeTime: String?) -> TimeRange {
        TimeRange(
            startHour: parseHour(openTime) ?? 6,
            endHour: parseHour(closeTime) ?? 21
        )
    }

    nonisolated static func parseHour(_ text: String?) -> Int? {
        guard let text else { return nil }
        let pattern = #"(\d{1,2})(?::\d{2})?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[range])
    }

    nonisolated static func parsePrice(_ text: String?) -> Int {
        // 필터 계산용 가격입니다. 순수 숫자/쉼표/원 형태만 금액으로 보고, 설명이 섞인 문자열은 0원 취급합니다.
        guard let normalizedPriceText = normalizedPriceText(text) else { return 0 }
        var numberText = normalizedPriceText.replacingOccurrences(of: ",", with: "")

        if numberText.hasSuffix("원") {
            numberText.removeLast()
        }

        guard numberText.allSatisfy(\.isNumber) else {
            return 0
        }

        return Int(numberText) ?? 0
    }

    nonisolated static func makePriceDisplayText(_ text: String?) -> String? {
        // 모달 리스트에서는 복잡한 가격 문구를 "상세 정보 확인"으로 통일해 높이가 흔들리지 않게 합니다.
        guard let text = nonEmptyTrimmed(text) else { return nil }
        return normalizedPriceText(text) ?? "상세 정보 확인"
    }

    nonisolated static func normalizedPriceText(_ text: String?) -> String? {
        // "20,000 원"처럼 숫자 뒤 공백이 있는 경우도 "20,000원"으로 정규화합니다.
        guard let text = nonEmptyTrimmed(text) else { return nil }

        let pattern = #"^(\d[\d,]*)(?:\s*(원))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let digits = text[numberRange].replacingOccurrences(of: ",", with: "")
        guard digits.allSatisfy(\.isNumber),
              let price = Int(digits) else {
            return nil
        }

        if price == 0 {
            return "무료"
        }

        let formattedPrice = price.formatted()
        return "\(formattedPrice)원"
    }

    nonisolated static func distanceFromDefaultLocation(latitude: Double, longitude: Double) -> Int {
        let defaultLatitude = 37.5665
        let defaultLongitude = 126.9780
        let earthRadius = 6_371_000.0
        let latitudeDelta = (latitude - defaultLatitude) * .pi / 180
        let longitudeDelta = (longitude - defaultLongitude) * .pi / 180
        let startLatitude = defaultLatitude * .pi / 180
        let endLatitude = latitude * .pi / 180
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return Int(earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine)))
    }

    nonisolated static func makeMatchingRate(price: Int, category: FacilityCategory) -> Int {
        let baseScore = 74 + (FacilityCategory.allCases.firstIndex(of: category) ?? 0) * 3
        let priceBonus = price == 0 ? 12 : max(0, 10 - price / 10_000)
        return min(98, baseScore + priceBonus)
    }

    nonisolated static func makeReservationURL(homepageURL: String?, fallbackKeyword: String) -> URL {
        if let url = makeWebURL(homepageURL) {
            return url
        }

        let keyword = fallbackKeyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?q=\(keyword)") ?? URL(string: "https://www.google.com")!
    }

    nonisolated static func makeWebURL(_ text: String?) -> URL? {
        guard let text = nonEmptyTrimmed(text),
              let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return nil
        }

        return url
    }

    nonisolated static func makeDescription(from facility: Facility) -> String {
        [
            facility.extraFacilityInfo,
            facility.usageStandardTime.map { "이용 기준: \($0)" },
            facility.excessRentalFee.map { "초과 사용료: \($0)" },
            facility.institution.map { "관리기관: \($0)" }
        ]
        .compactMap { $0 }
        .filter { $0.isEmpty == false }
        .joined(separator: "\n")
    }

    nonisolated static func makeProgramOperatingHoursText(
        program: Program,
        fallbackText: String
    ) -> String {
        if let startTime = nonEmptyTrimmed(program.startTime),
           let endTime = nonEmptyTrimmed(program.endTime) {
            let dayText = parseProgramDays(program.days).map(\.title).joined(separator: ", ")
            return "\(dayText) \(startTime) - \(endTime)"
        }

        return fallbackText
    }

    nonisolated static func makeOperatingHoursText(from facility: Facility) -> String {
        let weekday = makeTimeText(
            label: "평일",
            openTime: facility.weekdayOpenTime,
            closeTime: facility.weekdayCloseTime
        )
        let weekend = makeTimeText(
            label: "주말",
            openTime: facility.weekendOpenTime,
            closeTime: facility.weekendCloseTime
        )
        let closed = facility.closeDays.flatMap(nonEmptyTrimmed).map { "휴관일 \($0)" }
        let values = [weekday, weekend, closed].compactMap { $0 }
        return values.isEmpty ? "운영 시간 정보 없음" : values.joined(separator: "\n")
    }

    nonisolated static func makeTimeText(label: String, openTime: String?, closeTime: String?) -> String? {
        guard let openTime = nonEmptyTrimmed(openTime),
              let closeTime = nonEmptyTrimmed(closeTime) else {
            return nil
        }
        return "\(label) \(openTime) - \(closeTime)"
    }

    nonisolated static func makeApplicationMethodText(from facility: Facility) -> String {
        let methods = facility.reservationMethods.map(\.title)
        if methods.isEmpty == false {
            return methods.joined(separator: ", ")
        }
        return nonEmptyTrimmed(facility.homepageUrl).map { "홈페이지 신청: \($0)" } ?? "신청 방법 정보 없음"
    }

    nonisolated static func makeIntroduction(from facility: Facility) -> String {
        [
            facility.locationName,
            facility.facilityName,
            facility.facilityType,
            facility.capacity.map { "수용 인원 \($0)" },
            facility.area.map { "면적 \($0)" },
            facility.institution.map { "관리기관 \($0)" }
        ]
        .compactMap(nonEmptyTrimmed)
        .joined(separator: "\n")
    }

    nonisolated static func makeAmenities(from facility: Facility) -> [String] {
        guard let info = nonEmptyTrimmed(facility.extraFacilityInfo) else {
            return []
        }

        let separators = CharacterSet(charactersIn: ",/·ㆍ|")
        return info
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    nonisolated static func makeParkingInfo(from facility: Facility) -> String {
        let text = [facility.extraFacilityInfo, facility.facilityName, facility.locationName]
            .compactMap { $0 }
            .joined(separator: " ")
        if text.contains("주차") {
            return "주차 가능 여부는 시설에 문의해주세요."
        }
        return "주차 정보 없음"
    }

    nonisolated static func nonEmptyTrimmed(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmed.isEmpty == false else {
            return nil
        }
        return trimmed
    }

    nonisolated static func normalizedMatchText(_ value: String?) -> String {
        guard let value else { return "" }
        let removableCharacters = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "/\\|·ㆍ,._-()[]{}:;"))

        return value
            .lowercased()
            .components(separatedBy: removableCharacters)
            .joined()
    }

    nonisolated static func normalizedMatchText(_ values: [String?]) -> String {
        normalizedMatchText(values.compactMap { $0 }.joined(separator: " "))
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        return stride(from: 0, to: count, by: size).map { startIndex in
            Array(self[startIndex..<Swift.min(startIndex + size, count)])
        }
    }
}
