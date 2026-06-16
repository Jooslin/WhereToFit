//
//  FacilityProgramListItemViewModel.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation
import UIKit

/// 시설/프로그램 리스트 셀에 필요한 표시값만 모아둔 모델입니다.
/// `FitnessFacility` 전체를 셀이 직접 해석하지 않도록 하여, 다른 개발자가 같은 셀을 안전하게 재사용할 수 있습니다.
struct FacilityProgramListItemViewModel {
    let badgeText: String
    let distanceText: String
    let title: String
    let detailText: String
    let showsReservationBadge: Bool
    let priceText: String
    let imageURL: URL?
    let placeholderImageName: String
    let thumbnailBackgroundColor: UIColor

    init(
        badgeText: String,
        distanceText: String,
        title: String,
        detailText: String,
        showsReservationBadge: Bool,
        priceText: String,
        imageURL: URL?,
        placeholderImageName: String,
        thumbnailBackgroundColor: UIColor
    ) {
        self.badgeText = badgeText
        self.distanceText = distanceText
        self.title = title
        self.detailText = detailText
        self.showsReservationBadge = showsReservationBadge
        self.priceText = priceText
        self.imageURL = imageURL
        self.placeholderImageName = placeholderImageName
        self.thumbnailBackgroundColor = thumbnailBackgroundColor
    }

    init(facility: FitnessFacility) {
        // sourceKind에 따라 시설은 "시설" 배지, 프로그램은 매칭률 배지를 보여줍니다.
        self.init(
            badgeText: facility.sourceKind == .facility ? "시설" : "매칭률 \(facility.matchingRate)%",
            distanceText: "거리 \(facility.distanceText)",
            title: facility.listTitle,
            detailText: facility.listDetailText,
            showsReservationBadge: facility.requiresReservation,
            priceText: facility.listPriceText,
            imageURL: facility.imageURL,
            placeholderImageName: facility.facilityPlaceholderImageName,
            thumbnailBackgroundColor: facility.category.mapTintColor
        )
    }
}

private extension FitnessFacility {
    var listTitle: String {
        sourceKind == .facility ? displayLocationName : programListTitle
    }

    var listDetailText: String {
        // 시설 셀은 주소와 운영시간을, 프로그램 셀은 시설명과 수업 요일/시간을 우선 노출합니다.
        if sourceKind == .facility {
            return "\(address)  |  \(compactTimeText)"
        }

        return "\(displayLocationName)  |  \(dayText) \(compactTimeText)"
    }

    var listPriceText: String {
        // 모달 리스트에서는 사용자가 빠르게 비교할 수 있도록 프로그램 가격은 시작가 형태로 표시합니다.
        if sourceKind == .facility {
            return priceText
        }

        return price == 0 ? "무료" : "\(priceText)~"
    }

    var programListTitle: String {
        if sourceKind == .program {
            return name
        }

        switch category {
        case .swimming: return "수영"
        case .tennis: return "테니스장 대관"
        case .soccer: return "축구장 대관"
        case .futsal: return "풋살장 대관"
        case .basketball: return "농구장 대관"
        case .baseball: return "야구장 대관"
        case .yoga: return "요가 클래스"
        case .pilates: return "필라테스"
        case .gym: return "헬스장 자유 이용"
        default: return "\(category.title) 프로그램"
        }
    }

    var displayLocationName: String {
        locationName?.isEmpty == false ? locationName ?? name : name
    }

    var compactTimeText: String {
        let start = String(format: "%02d:00", availableTimeRange.startHour)
        let endHour = availableTimeRange.endHour == 24 ? "24:00" : String(format: "%02d:00", availableTimeRange.endHour)
        return "\(start)-\(endHour)"
    }
}
