//
//  RecommendSportsUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class RecommendSportsUseCase {
    private let repository: SportRecommendationRuleRepositoryProtocol
    private let calendar: Calendar
    
    init(
        repository: SportRecommendationRuleRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }
    
    func execute(profile: UserProfile) -> Single<[RecommendedSport]> {
        executePersonalizedScores(profile: profile)
            .map(Self.visibleRecommendations)
    }
    
    func executePersonalizedScores(profile: UserProfile) -> Single<[RecommendedSport]> {
        repository.fetchActiveRules()
            .map { [calendar] rules in
                Self.scoredSports(
                    profile: profile,
                    rules: rules,
                    calendar: calendar,
                    includesPersonalization: true
                )
            }
    }
    
    func executeCategory(profile: UserProfile) -> Single<[RecommendedSport]> {
        repository.fetchActiveRules()
            .map { [calendar] rules in
                Self.scoredSports(
                    profile: profile,
                    rules: rules,
                    calendar: calendar,
                    includesPersonalization: false
                )
            }
    }
}

private extension RecommendSportsUseCase {
    static let primaryThreshold = 70
    static let fallbackThreshold = 60
    static let minimumRecommendationCount = 3
    static let maximumVisibleRecommendationCount = 8
    static let preferredCategoryBonus = 5
    
    static func scoredSports(
        profile: UserProfile,
        rules: [SportRecommendationRule],
        calendar: Calendar,
        includesPersonalization: Bool
    ) -> [RecommendedSport] {
        rules
            .map { rule in
                RecommendedSport(
                    sportName: rule.sportName,
                    sportsCategory: rule.sportsCategory,
                    matchRate: matchRate(
                        profile: profile,
                        rule: rule,
                        calendar: calendar,
                        includesPersonalization: includesPersonalization
                    )
                )
            }
            .sorted {
                if $0.matchRate == $1.matchRate {
                    return $0.sportName < $1.sportName
                }
                
                return $0.matchRate > $1.matchRate
            }
    }
    
    static func visibleRecommendations(from scoredSports: [RecommendedSport]) -> [RecommendedSport] {
        var recommendations = scoredSports.filter { $0.matchRate >= primaryThreshold }
        if recommendations.count < minimumRecommendationCount {
            recommendations = scoredSports.filter { $0.matchRate >= fallbackThreshold }
        }
        
        return Array(recommendations.prefix(maximumVisibleRecommendationCount))
    }
    
    static func matchRate(
        profile: UserProfile,
        rule: SportRecommendationRule,
        calendar: Calendar,
        includesPersonalization: Bool
    ) -> Int {
        let ageScore = rule.ageWeights[ageGroup(for: profile.birthDate, calendar: calendar)] ?? 0
        let experienceScore = profile.exerciseExperience
            .map { rule.experienceWeights[$0.rawValue] ?? 0 } ?? 0
        let goalScore = profile.exerciseGoal
            .map { rule.goalWeights[goalKey(for: $0)] ?? 0 } ?? 0
        
        let scores: [Int]
        let bonus: Int
        if includesPersonalization {
            let bodyPartScore = bodyPartSuitabilityScore(
                discomfortBodyParts: profile.discomfortBodyParts,
                riskWeights: rule.bodyPartRiskWeights
            )
            scores = [ageScore, experienceScore, goalScore, bodyPartScore]
            bonus = profile.preferredSportsCategories.contains(rule.sportsCategory)
                ? preferredCategoryBonus
                : 0
        } else {
            scores = [ageScore, experienceScore, goalScore]
            bonus = 0
        }
        
        let baseScore = Double(scores.reduce(0, +)) / Double(scores.count)
        
        return min(100, Int((baseScore + Double(bonus)).rounded()))
    }
    
    static func bodyPartSuitabilityScore(
        discomfortBodyParts: [DiscomfortBodyPart],
        riskWeights: [String: Int]
    ) -> Int {
        guard discomfortBodyParts.isEmpty == false else {
            return 100
        }
        
        let maxRisk = discomfortBodyParts
            .map { riskWeights[$0.rawValue] ?? 0 }
            .max() ?? 0
        
        return max(0, 100 - maxRisk)
    }
    
    static func ageGroup(for birthDate: Date, calendar: Calendar) -> String {
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        switch age {
        case ..<7:
            return "아이"
        case 7..<13:
            return "어린이"
        case 13..<20:
            return "청소년"
        case 20..<30:
            return "20대"
        case 30..<40:
            return "30대"
        case 40..<50:
            return "40대"
        case 50..<60:
            return "50대"
        default:
            return "60대 이상"
        }
    }
    
    static func goalKey(for goal: ExerciseGoal) -> String {
        switch goal {
        case .strengthImprovement:
            return "근력향상"
        case .diet:
            return "다이어트"
        case .fitnessImprovement:
            return "체력향상"
        case .postureCorrection:
            return "자세교정"
        case .healthCare:
            return "건강관리"
        case .stressRelief:
            return "스트레스 해소"
        }
    }
}
