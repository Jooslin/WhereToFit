//
//  CalendarRecord.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation

nonisolated enum RecordSource: String, Equatable, Sendable {
    case manual
    case healthKit
}

nonisolated struct WeightRecord: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let date: Date
    let value: Double
    let source: RecordSource
    let createdAt: Date
    let updatedAt: Date
}

nonisolated struct ConditionRecord: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let date: Date
    let condition: ConditionLevel
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum ConditionLevel: String, Equatable, Sendable {
    case veryGood
    case good
    case normal
    case bad
    case worst
}

nonisolated struct ExerciseRecord: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let date: Date
    let exerciseName: String
    let activityTypeRawValue: Int?
    let sportsCategoryRawValue: String?
    let duration: TimeInterval
    let calories: Double?
    let source: RecordSource
    let healthKitUUID: UUID?
    let startDate: Date?
    let endDate: Date?
    let createdAt: Date
    let updatedAt: Date

    var isEditable: Bool {
        source == .manual
    }

    var isDeletable: Bool {
        source == .manual
    }
}
