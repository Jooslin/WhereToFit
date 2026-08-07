//
//  ProgramMatchRateCalculator.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation

enum ProgramMatchRateCalculator {
    struct Context {
        let profile: UserProfile
        let categorySports: [RecommendedSport]
        let personalizedSports: [RecommendedSport]
    }
    
    struct ProgramScore {
        let selectionSportScore: Int
        let levelScore: Int
        let selectionScore: Int
        let matchRate: Int
    }
    
    static func programScore(
        for program: Program,
        context: Context
    ) -> ProgramScore? {
        guard let selectionSportScore = sportScore(
            for: program,
            from: context.categorySports
        ), isAgeEligible(program: program, profile: context.profile) else {
            return nil
        }
        
        let personalizedSportScore = sportScore(
            for: program,
            from: context.personalizedSports
        ) ?? selectionSportScore
        let levelScore = levelConditionScore(program: program, profile: context.profile)
        
        return ProgramScore(
            selectionSportScore: selectionSportScore,
            levelScore: levelScore,
            selectionScore: average([selectionSportScore, levelScore]),
            matchRate: average([personalizedSportScore, levelScore])
        )
    }
    
    static func facilityMatchRate(
        category: FacilityCategory,
        context: Context
    ) -> Int? {
        let sportsCategory = SportsCategory(sport: category.title)
        let normalizedCategoryTitle = normalizedSportName(category.title)
        
        if let exactScore = context.personalizedSports.first(where: {
            normalizedSportName($0.sportName) == normalizedCategoryTitle
        })?.matchRate {
            return exactScore
        }
        
        return context.personalizedSports
            .filter { $0.sportsCategory == sportsCategory }
            .map(\.matchRate)
            .max()
    }
}

private extension ProgramMatchRateCalculator {
    static func sportScore(
        for program: Program,
        from sports: [RecommendedSport]
    ) -> Int? {
        let normalizedProgramSport = normalizedSportName(program.sport)
        
        if let normalizedProgramSport,
           let exactScore = sports.first(where: {
               normalizedSportName($0.sportName) == normalizedProgramSport
           })?.matchRate {
            return exactScore
        }
        
        return sports
            .filter { $0.sportsCategory == program.sportsCategory }
            .map(\.matchRate)
            .max()
    }
    
    static func isAgeEligible(program: Program, profile: UserProfile) -> Bool {
        guard program.targetAges.isEmpty == false,
              program.targetAges.contains(.all) == false else {
            return true
        }
        
        let targetAge = programTargetAge(for: profile.birthDate)
        return program.targetAges.contains(targetAge)
    }
    
    static func programTargetAge(for birthDate: Date) -> ProgramTargetAge {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        switch age {
        case ..<7:
            return .infant
        case 7..<13:
            return .child
        case 13..<20:
            return .youth
        case 20..<60:
            return .adult
        default:
            return .senior
        }
    }
    
    static func levelConditionScore(program: Program, profile: UserProfile) -> Int {
        guard program.levels.isEmpty == false,
              program.levels.contains(.all) == false,
              let expectedLevel = programLevel(for: profile.exerciseExperience) else {
            return 100
        }
        
        if program.levels.contains(expectedLevel) {
            return 100
        }
        
        switch expectedLevel {
        case .beginner:
            return program.levels.contains(.intermediate) ? 70 : 50
        case .intermediate:
            return program.levels.contains(.beginner) || program.levels.contains(.advanced) ? 75 : 50
        case .advanced:
            return program.levels.contains(.intermediate) ? 75 : 50
        case .all:
            return 100
        }
    }
    
    static func programLevel(for experience: ExerciseExperience?) -> ProgramLevel? {
        switch experience {
        case .starter, .beginner:
            return .beginner
        case .intermediate:
            return .intermediate
        case .advanced:
            return .advanced
        case .none:
            return nil
        }
    }
    
    static func average(_ scores: [Int]) -> Int {
        Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
    }
    
    static func normalizedSportName(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension ProgramMatchRateCalculator {
    func mathRate() -> Int {
        // ruleScore 가중치 50% 선호 카테고리 15% 거리 35% -- AI 종목 추천
        // ruleScore 65% 거리 35% -- 프로그램 추천
        // 온보딩 없을 경우 거리 100%
        return 0
    }
    
    static func ruleScore(
        profile: UserProfile,
        rule: SportRecommendationRule,
        ageGroup: String,
        includesBodyPart: Bool
    ) throws -> Int {
        guard let experience = profile.exerciseExperience else {
            throw RuleScoreError.missingExerciseExperience
        }
        
        guard let goal = profile.exerciseGoal else {
            throw RuleScoreError.missingExerciseGoal
        }
        
        guard let ageScore = rule.ageWeights[ageGroup] else {
            throw RuleScoreError.missingAgeWeight(ageGroup)
        }
        
        guard let experienceScore = rule.experienceWeights[experience.rawValue] else {
            throw RuleScoreError.missingExperienceWeight(experience.rawValue)
        }
        
        guard let goalScore = rule.goalWeights[goal.rawValue] else {
            throw RuleScoreError.missingGoalWeight(goal.rawValue)
        }
        
        var scores = [
            ageScore,
            experienceScore,
            goalScore
        ]
        
        if includesBodyPart {
            let risks = try profile.discomfortBodyParts.map { bodyPart in
                guard let risk = rule.bodyPartRiskWeights[bodyPart.rawValue] else {
                    throw RuleScoreError.missingBodyPartRiskWeight(bodyPart.rawValue)
                }
                
                return risk
            }
            
            let maximumRisk = risks.max() ?? 0
            let bodyPartScore = max(0, 100 - maximumRisk)
            
            scores.append(bodyPartScore)
        }
        
        let average = Double(scores.reduce(0, +)) / Double(scores.count)
        
        return Int(average.rounded())
    }
}

//MARK: Error
extension ProgramMatchRateCalculator {
    enum RuleScoreError: LocalizedError {
        case missingExerciseExperience
        case missingExerciseGoal
        case missingAgeWeight(String)
        case missingExperienceWeight(String)
        case missingGoalWeight(String)
        case missingBodyPartRiskWeight(String)
        
        var errorDescription: String? {
            switch self {
            case .missingExerciseExperience:
                return "운동 숙련도 정보가 없습니다."
                
            case .missingExerciseGoal:
                return "운동 목표 정보가 없습니다."
                
            case .missingAgeWeight(let ageGroup):
                return "연령대 '\(ageGroup)'에 해당하는 추천 룰이 없습니다."
                
            case .missingExperienceWeight(let experience):
                return "숙련도 '\(experience)'에 해당하는 추천 룰이 없습니다."
                
            case .missingGoalWeight(let goal):
                return "운동 목표 '\(goal)'에 해당하는 추천 룰이 없습니다."
                
            case .missingBodyPartRiskWeight(let bodyPart):
                return "불편 신체 부위 '\(bodyPart)'에 해당하는 위험도 룰이 없습니다."
            }
        }
    }
    
    
}
