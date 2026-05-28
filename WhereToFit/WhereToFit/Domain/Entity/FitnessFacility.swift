//
//  FitnessFacility.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import Foundation

// MARK: - 시설의 위치 (위경도)
struct GeoCoordinate: Equatable {
    let latitude: Double // 위도
    let longitude: Double // 경도
}


// MARK: - 운동 종목 카테고리
enum FacilityCategory: String, CaseIterable, Equatable {
    case soccer
    case gym
    case pilates
    case swimming
    case tennis
    case climbing

    var title: String {
        switch self {
        case .soccer: return "축구"
        case .gym: return "헬스"
        case .pilates: return "필라테스"
        case .swimming: return "수영"
        case .tennis: return "테니스"
        case .climbing: return "클라이밍"
        }
    }
}


// MARK: - 운영 요일
enum DayOfWeek: String, CaseIterable, Equatable {
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


// MARK: - 가격 범위
enum PriceRange: String, CaseIterable, Equatable {
    case underTenThousand
    case tenToThirtyThousand
    case overThirtyThousand

    var title: String {
        switch self {
        case .underTenThousand: return "1만원 이하"
        case .tenToThirtyThousand: return "1~3만원"
        case .overThirtyThousand: return "3만원 이상"
        }
    }
}


// MARK: - 이용 가능 시간 범위
struct TimeRange: Equatable {
    let startHour: Int
    let endHour: Int

    var title: String {
        "\(startHour):00-\(endHour):00"
    }

    // 사용자가 고른 시간 필터와 시설 운영 시간이 겹치는지 확인하는 메서드
    func overlaps(_ other: TimeRange) -> Bool {
        startHour < other.endHour && other.startHour < endHour
    }
}


// MARK: - 사용자가 선택한 필터 상태
struct FacilityFilter: Equatable {
    var isAIRecommendationEnabled: Bool
    var category: FacilityCategory?
    var priceRange: PriceRange?
    var day: DayOfWeek?
    var timeRange: TimeRange?

    // 아무것도 선택하지 않은 기본 상태
    static let empty = FacilityFilter(
        isAIRecommendationEnabled: false,
        category: nil,
        priceRange: nil,
        day: nil,
        timeRange: nil
    )
}


// MARK: - 시설 하나의 실제 데이터
struct FitnessFacility: Equatable, Identifiable {
    let id: String
    let name: String
    let category: FacilityCategory
    let coordinate: GeoCoordinate
    let distanceInMeters: Int // 내 위치와의 거리
    let price: Int
    let availableDays: [DayOfWeek]
    let availableTimeRange: TimeRange
    let imageURL: URL?
    var isFavorite: Bool // 찜 여부
    let requiresReservation: Bool // 예약 필요 여부
    let matchingRate: Int // 매칭률
    let reservationURL: URL // 예약 링크
    let description: String

    var distanceText: String {
        // m -> km로 변환
        if distanceInMeters >= 1000 {
            return String(format: "%.1fkm", Double(distanceInMeters) / 1000)
        }
        return "\(distanceInMeters)m"
    }

    // 가격 텍스트로 변환 (25,000원)
    var priceText: String {
        price == 0 ? "무료" : "\(price.formatted())원"
    }

    // 배열 안 문자열을 하나의 문자열로 합치기
    var dayText: String {
        availableDays.map(\.title).joined(separator: ", ")
    }
}
