//
//  Favorite.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

/*
 FavoriteTargetType를 기준으로 찜한 화면에서 시설/프로그램 탭을 나누어서 뿌립니다.
 */
import Foundation

nonisolated struct Favorite: Equatable, Sendable {
    let id: UUID
    let targetType: FavoriteTargetType
    let targetID: String // 시설/프로그램 아이디
    let name: String // 시설/프로그램 이름
    let programCenterName: String? // 프로그램일 경우 - 시설 이름 넣기
    let sportsCategoryRawValue: String?
    let snapshotJSON: String?
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum FavoriteTargetType: String, Hashable, Sendable {
    case facility
    case program
}

nonisolated struct FavoriteTargetKey: Hashable, Sendable {
    let targetType: FavoriteTargetType
    let targetID: String

    init(targetType: FavoriteTargetType, targetID: String) {
        self.targetType = targetType
        self.targetID = targetID
    }

    init(favorite: Favorite) {
        self.init(targetType: favorite.targetType, targetID: favorite.targetID)
    }

    init(facility: FitnessFacility) {
        let targetType: FavoriteTargetType = facility.sourceKind == .facility ? .facility : .program
        self.init(targetType: targetType, facility: facility)
    }

    init(targetType: FavoriteTargetType, facility: FitnessFacility) {
        switch targetType {
        case .facility:
            self.init(targetType: targetType, targetID: facility.sourceFacilityID ?? facility.id)
        case .program:
            self.init(targetType: targetType, targetID: facility.id)
        }
    }
}
