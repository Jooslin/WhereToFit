//
//  UserProfile.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation

nonisolated struct UserProfile: Equatable, Sendable {
    let id: UUID // 식별용
    let nickname: String // 닉네임
    let birthDate: Date // 생년월일
    let gender: UserGender // 성별
    let residenceAddress: String? // 거주지역
    let residenceLatitude: Double? // 지역 좌표
    let residenceLongitude: Double? // 지역 좌표
    let height: Double? // 신장
    let initialWeight: Double? // 몸무게
    let exerciseExperience: ExerciseExperience? // 운동 경험
    let exerciseGoals: [ExerciseGoal] // 운동 목표
    let preferredSportsCategoryRawValues: [String] // 운동 선호(복수 선택)
    let discomfortBodyParts: [DiscomfortBodyPart] // 불편한 신체부위(복수 선택)
    let usesPublicFacility: Bool // 시설 이용 여부
    let createdAt: Date // 만든 날짜 ( 몸무게, 신장 표시 때 필요)
    let updatedAt: Date // 업데이트 여부 
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
