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
    let targetID: String
    let title: String
    let subtitle: String?
    let sportsCategoryRawValue: String?
    let snapshotJSON: String?
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum FavoriteTargetType: String, Equatable, Sendable {
    case facility
    case program
}
