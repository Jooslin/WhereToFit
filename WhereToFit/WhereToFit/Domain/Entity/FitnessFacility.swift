//
//  FitnessFacility.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import Foundation


// MARK: - 시설의 위치 (위경도)
nonisolated struct GeoCoordinate: Equatable, Sendable {
    let latitude: Double // 위도
    let longitude: Double // 경도
}

nonisolated struct FitnessFacilityDataSet: Equatable {
    let markerFacilities: [FitnessFacility] // 지도 아이콘 기준 시설 데이터
    let programFacilities: [FitnessFacility] // 하단 모달 데이터
}

nonisolated enum FitnessFacilitySourceKind: Equatable {
    case facility // 시설
    case program // 프로그램
}


// MARK: - 운동 종목 카테고리
nonisolated enum FacilityCategory: String, CaseIterable, Hashable {
    case gym
    case healthPT
    case bodybuilding
    case gx
    case trx
    case circuitTraining
    case spinningBike
    case aerobics
    case dietRobics
    case seniorRobics
    case taebo
    case jumpingDiet
    case jumpingTrampoline
    case fitBalance
    case womensCircuitExercise
    case yoga
    case powerYoga
    case pilates
    case snpe
    case gymnastics
    case kuksundo
    case koreanQigong
    case taiChi
    case lifeGymnastics
    case stretching
    case dance
    case lineDance
    case broadcastDance
    case bellyDance
    case sportsDance
    case zumbaDance
    case dietDance
    case ballet
    case traditionalDance
    case koreanDance
    case swimming
    case survivalSwimming
    case aquaticHealthGymnastics
    case aquaRobics
    case aquaWalking
    case aquathlon
    case artisticSwimming
    case scubaDiving
    case basketball
    case soccer
    case futsal
    case baseball
    case badminton
    case tableTennis
    case tennis
    case squash
    case racquetball
    case pickleball
    case golf
    case parkGolf
    case gateball
    case billiards
    case bowling
    case floorball
    case volleyball
    case skating
    case speedSkating
    case figureSkating
    case skiing
    case kendo
    case boxing
    case judo
    case taekwondo
    case taekkyeon
    case fencing
    case traditionalArchery
    case running
    case jogging
    case athletics
    case cycling
    case runBike
    case triathlon
    case lifeSports
    case childSports
    case infantSports
    case jumpRope
    case womensHealthClass
    case bodySkillRelease
    case boccia
    case sBoard
    case rollerSkating
    case hiking
    case climbing
    case multipurpose

    var title: String {
        switch self {
        case .gym: return "헬스"
        case .healthPT: return "헬스PT"
        case .bodybuilding: return "보디빌딩"
        case .gx: return "GX"
        case .trx: return "TRX"
        case .circuitTraining: return "서킷트레이닝"
        case .spinningBike: return "스피닝바이크"
        case .aerobics: return "에어로빅"
        case .dietRobics: return "다이어트로빅"
        case .seniorRobics: return "시니어로빅"
        case .taebo: return "태보"
        case .jumpingDiet: return "점핑다이어트"
        case .jumpingTrampoline: return "점핑트램폴린"
        case .fitBalance: return "핏밸런스"
        case .womensCircuitExercise: return "여성순환운동"
        case .yoga: return "요가"
        case .powerYoga: return "파워요가"
        case .pilates: return "필라테스"
        case .snpe: return "SNPE"
        case .gymnastics: return "체조"
        case .kuksundo: return "국선도"
        case .koreanQigong: return "국학기공"
        case .taiChi: return "태극권"
        case .lifeGymnastics: return "생활체조"
        case .stretching: return "스트레칭"
        case .dance: return "댄스"
        case .lineDance: return "라인댄스"
        case .broadcastDance: return "방송댄스"
        case .bellyDance: return "벨리댄스"
        case .sportsDance: return "스포츠댄스"
        case .zumbaDance: return "줌바댄스"
        case .dietDance: return "다이어트댄스"
        case .ballet: return "발레"
        case .traditionalDance: return "전통무용"
        case .koreanDance: return "한국무용"
        case .swimming: return "수영"
        case .survivalSwimming: return "생존수영"
        case .aquaticHealthGymnastics: return "수중보건체조"
        case .aquaRobics: return "아쿠아로빅"
        case .aquaWalking: return "아쿠아워킹"
        case .aquathlon: return "아쿠아슬론"
        case .artisticSwimming: return "아티스틱 스위밍"
        case .scubaDiving: return "스킨스쿠버"
        case .basketball: return "농구"
        case .soccer: return "축구"
        case .futsal: return "풋살"
        case .baseball: return "야구"
        case .badminton: return "배드민턴"
        case .tableTennis: return "탁구"
        case .tennis: return "테니스"
        case .squash: return "스쿼시"
        case .racquetball: return "라켓볼"
        case .pickleball: return "피클볼"
        case .golf: return "골프"
        case .parkGolf: return "파크골프"
        case .gateball: return "게이트볼"
        case .billiards: return "당구"
        case .bowling: return "볼링"
        case .floorball: return "플로어볼"
        case .volleyball: return "배구"
        case .skating: return "스케이트"
        case .speedSkating: return "스피드 스케이팅"
        case .figureSkating: return "피겨"
        case .skiing: return "스키"
        case .kendo: return "검도"
        case .boxing: return "복싱"
        case .judo: return "유도"
        case .taekwondo: return "태권도"
        case .taekkyeon: return "택견"
        case .fencing: return "펜싱"
        case .traditionalArchery: return "국궁"
        case .running: return "러닝"
        case .jogging: return "달리기"
        case .athletics: return "육상"
        case .cycling: return "자전거"
        case .runBike: return "런바이크"
        case .triathlon: return "철인 3종"
        case .lifeSports: return "생활체육"
        case .childSports: return "아동체육"
        case .infantSports: return "유아체육"
        case .jumpRope: return "줄넘기"
        case .womensHealthClass: return "여성건강교실"
        case .bodySkillRelease: return "바디스킬릴리즈"
        case .boccia: return "보치아"
        case .sBoard: return "S보드"
        case .rollerSkating: return "롤러스케이트"
        case .hiking: return "등산"
        case .climbing: return "클라이밍"
        case .multipurpose: return "기타"
        }
    }
}


// MARK: - 운영 요일
nonisolated enum DayOfWeek: String, CaseIterable, Hashable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var title: String {
        switch self {
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        case .sunday: return "일"
        }
    }
}


// MARK: - 이용 가능 시간 범위
nonisolated struct TimeRange: Equatable {
    let startHour: Int
    let endHour: Int

    var title: String {
        "\(startHour):00-\(endHour):00"
    }

    // 사용자가 고른 시간 필터와 시설 운영 시간이 겹치는지 확인하는 메서드
    func overlaps(_ other: TimeRange) -> Bool {
        normalizedSegments.contains { lhs in
            other.normalizedSegments.contains { rhs in
                lhs.start < rhs.end && rhs.start < lhs.end
            }
        }
    }

    private var normalizedSegments: [(start: Int, end: Int)] {
        if startHour < endHour {
            return [(startHour, endHour)]
        }

        return [(startHour, 24), (0, endHour)]
    }
}


// MARK: - 시간 필터
nonisolated enum TimeSlot: String, CaseIterable, Hashable {
    case dawn
    case morning
    case forenoon
    case afternoon
    case evening
    case night

    var title: String {
        switch self {
        case .dawn: return "새벽"
        case .morning: return "아침"
        case .forenoon: return "오전"
        case .afternoon: return "오후"
        case .evening: return "저녁"
        case .night: return "야간"
        }
    }

    var range: TimeRange {
        switch self {
        case .dawn: return TimeRange(startHour: 0, endHour: 7)
        case .morning: return TimeRange(startHour: 7, endHour: 9)
        case .forenoon: return TimeRange(startHour: 9, endHour: 12)
        case .afternoon: return TimeRange(startHour: 12, endHour: 17)
        case .evening: return TimeRange(startHour: 17, endHour: 21)
        case .night: return TimeRange(startHour: 21, endHour: 24)
        }
    }
}


// MARK: - 사용자가 선택한 필터 상태
nonisolated struct FacilityFilter: Equatable {
    var isAIRecommendationEnabled: Bool
    var categories: Set<FacilityCategory>
    var minimumPrice: Int?
    var maximumPrice: Int?
    var days: Set<DayOfWeek>
    var timeSlots: Set<TimeSlot>

    // 아무것도 선택하지 않은 기본 상태
    static let empty = FacilityFilter(
        isAIRecommendationEnabled: false,
        categories: [],
        minimumPrice: nil,
        maximumPrice: nil,
        days: [],
        timeSlots: []
    )
}


// MARK: - 시설 하나의 실제 데이터
nonisolated struct FitnessFacility: Equatable, Identifiable {
    let id: String
    let name: String
    let address: String
    let phoneNumber: String
    let category: FacilityCategory
    let coordinate: GeoCoordinate
    let distanceInMeters: Int // 내 위치와의 거리
    let price: Int
    let priceDisplayText: String?
    let rawPriceText: String?
    let availableDays: [DayOfWeek]
    let availableTimeRange: TimeRange
    let imageURL: URL?
    var isFavorite: Bool // 찜 여부
    let requiresReservation: Bool // 예약 필요 여부
    let matchingRate: Int // 매칭률
    let reservationURL: URL // 예약 링크
    let homepageURL: URL?
    let description: String
    let locationName: String?
    let facilityType: String?
    let operatingHoursText: String
    let applicationMethodText: String
    let introduction: String
    let amenities: [String]
    let parkingInfo: String
    let sourceKind: FitnessFacilitySourceKind
    let sourceFacilityID: String?
    let sourceProgramID: Int?

    init(
        id: String,
        name: String,
        address: String,
        phoneNumber: String,
        category: FacilityCategory,
        coordinate: GeoCoordinate,
        distanceInMeters: Int,
        price: Int,
        priceDisplayText: String? = nil,
        rawPriceText: String? = nil,
        availableDays: [DayOfWeek],
        availableTimeRange: TimeRange,
        imageURL: URL?,
        isFavorite: Bool,
        requiresReservation: Bool,
        matchingRate: Int,
        reservationURL: URL,
        homepageURL: URL? = nil,
        description: String,
        locationName: String? = nil,
        facilityType: String? = nil,
        operatingHoursText: String = "운영 시간 정보 없음",
        applicationMethodText: String = "신청 방법 정보 없음",
        introduction: String = "시설 소개 정보 없음",
        amenities: [String] = [],
        parkingInfo: String = "주차 정보 없음",
        sourceKind: FitnessFacilitySourceKind = .facility,
        sourceFacilityID: String? = nil,
        sourceProgramID: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.phoneNumber = phoneNumber
        self.category = category
        self.coordinate = coordinate
        self.distanceInMeters = distanceInMeters
        self.price = price
        self.priceDisplayText = priceDisplayText
        self.rawPriceText = rawPriceText
        self.availableDays = availableDays
        self.availableTimeRange = availableTimeRange
        self.imageURL = imageURL
        self.isFavorite = isFavorite
        self.requiresReservation = requiresReservation
        self.matchingRate = matchingRate
        self.reservationURL = reservationURL
        self.homepageURL = homepageURL
        self.description = description
        self.locationName = locationName
        self.facilityType = facilityType
        self.operatingHoursText = operatingHoursText
        self.applicationMethodText = applicationMethodText
        self.introduction = introduction
        self.amenities = amenities
        self.parkingInfo = parkingInfo
        self.sourceKind = sourceKind
        self.sourceFacilityID = sourceFacilityID
        self.sourceProgramID = sourceProgramID
    }

    var distanceText: String {
        // m -> km로 변환
        if distanceInMeters >= 1000 {
            return String(format: "%.1fkm", Double(distanceInMeters) / 1000)
        }
        return "\(distanceInMeters)m"
    }

    // 가격 텍스트로 변환 (25,000원)
    var priceText: String {
        if let priceDisplayText,
           priceDisplayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return priceDisplayText
        }
        return price == 0 ? "무료" : "\(price.formatted())원"
    }

    // 배열 안 문자열을 하나의 문자열로 합치기
    var dayText: String {
        availableDays.map(\.title).joined(separator: ", ")
    }
}
