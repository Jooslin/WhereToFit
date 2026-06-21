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
        ) else {
            return nil
        }

        let personalizedSportScore = sportScore(
            for: program,
            from: context.personalizedSports
        ) ?? selectionSportScore
        let ageScore = ageConditionScore(program: program, profile: context.profile)
        let levelScore = levelConditionScore(program: program, profile: context.profile)

        return ProgramScore(
            selectionScore: average([selectionSportScore, ageScore, levelScore]),
            matchRate: average([personalizedSportScore, ageScore, levelScore])
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

    static func ageConditionScore(program: Program, profile: UserProfile) -> Int {
        guard program.targetAges.isEmpty == false,
              program.targetAges.contains(.all) == false else {
            return 100
        }

        let targetAge = programTargetAge(for: profile.birthDate)
        return program.targetAges.contains(targetAge) ? 100 : 45
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
