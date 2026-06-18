//
//  UserProfile.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation

nonisolated struct UserProfile: Equatable, Sendable {
    let id: UUID
    let nickname: String
    let birthDate: Date
    let gender: UserGender
    let residenceAddress: String?
    let residenceLatitude: Double?
    let residenceLongitude: Double?
    let height: Double?
    let initialWeight: Double?
    let exerciseExperience: ExerciseExperience?
    let exerciseGoals: [ExerciseGoal]
    let preferredSportsCategoryRawValues: [String]
    let discomfortBodyParts: [DiscomfortBodyPart]
    let usesPublicFacility: Bool
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum UserGender: String, Equatable, Sendable {
    case male
    case female
}

nonisolated enum ExerciseExperience: String, Equatable, Sendable {
    case starter
    case beginner
    case intermediate
    case advanced
}

nonisolated enum ExerciseGoal: String, Equatable, Sendable {
    case strengthImprovement
    case diet
    case fitnessImprovement
    case postureCorrection
    case healthCare
    case stressRelief
}

nonisolated enum DiscomfortBodyPart: String, Equatable, Sendable {
    case dizziness
    case neck
    case shoulder
    case elbow
    case wrist
    case lowerBack
    case knee
    case ankle
}
