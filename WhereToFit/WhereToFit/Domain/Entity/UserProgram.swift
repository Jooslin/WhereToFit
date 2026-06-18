//
//  UserProgram.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation

nonisolated struct RegisteredProgram: Equatable, Sendable {
    let id: UUID
    let programID: Int?
    let facilityID: String?
    let programName: String
    let facilityName: String?
    let sportsCategoryRawValue: String?
    let days: [String]
    let startTime: String?
    let endTime: String?
    let reservationMethodRawValues: [String]
    let createdAt: Date
    let updatedAt: Date
}

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
