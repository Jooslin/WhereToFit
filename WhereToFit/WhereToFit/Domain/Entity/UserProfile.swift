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
    let height: Double? // 신장
    let initialWeight: Double? // 몸무게
    let exerciseExperience: ExerciseExperience? // 운동 경험
    let exerciseGoal: ExerciseGoal? // 운동 목표
    let preferredSportsCategoryRawValues: [String] // 운동 선호(복수 선택)
    let discomfortBodyParts: [DiscomfortBodyPart] // 불편한 신체부위(복수 선택)
    let usesPublicFacility: Bool // 시설 이용 여부
    let createdAt: Date // 만든 날짜 ( 몸무게, 신장 표시 때 필요)
    let updatedAt: Date // 업데이트 여부 
}

// 유저 장소 저장 
nonisolated struct UserLocation: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let isSelected: Bool
    let kind: UserLocationKind
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum UserLocationKind: String, Equatable, Sendable {
    case home
    case office
    case custom
}

nonisolated enum UserGender: String, Equatable, Sendable {
    case male = "남성"
    case female = "여성"
}

nonisolated enum ExerciseExperience: String, Equatable, Sendable, CaseIterable {
    case starter = "초보"
    case beginner = "입문"
    case intermediate = "중급"
    case advanced = "숙련"
    
    var subTitle: String {
        switch self {
        case .starter: "이제 시작하는 단계예요"
        case .beginner: "가볍게 경험해봤어요"
        case .intermediate: "꾸준히 운동하고 있어요"
        case .advanced: "어느 운동이든 잘 해내요"
        }
    }
}

nonisolated enum ExerciseGoal: String, Equatable, Sendable, CaseIterable {
    case strengthImprovement = "근력 향상"
    case diet = "다이어트"
    case fitnessImprovement = "체력 향상"
    case postureCorrection = "자세 교정"
    case healthCare = "건강 관리"
    case stressRelief = "스트레스 해소"
    
    var imageName: String {
        switch self {
        case .strengthImprovement: "strengthImprovement"
        case .diet: "diet"
        case .fitnessImprovement: "fitnessImprovement"
        case .postureCorrection: "postureCorrection"
        case .healthCare: "healthCare"
        case .stressRelief: "stressRelief"
        }
    }
}

nonisolated enum DiscomfortBodyPart: String, Equatable, Sendable, CaseIterable {
    case dizziness = "어지럼증"
    case neck = "목"
    case shoulder = "어깨"
    case elbow = "팔꿈치"
    case wrist = "손목"
    case lowerBack = "허리"
    case knee = "무릎"
    case ankle = "발목"
    
    var imageString: String {
        switch self {
        case .dizziness: "dizziness"
        case .neck: "neck"
        case .shoulder: "shoulder"
        case .elbow: "elbow"
        case .wrist: "wrist"
        case .lowerBack: "lowerBack"
        case .knee: "knee"
        case .ankle: "ankle"
        }
    }
}
