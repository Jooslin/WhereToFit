//
//  SportRecommendationRule.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation

nonisolated struct SportRecommendationRule: Equatable, Sendable {
    let id: Int
    let sportsName: String
    let sportsCategory: SportsCategory
    let ageWeights: [String: Int]
    let experienceWeights: [String: Int]
    let goalWeights: [String: Int]
    let bodyPartRiskWeights: [String: Int]
    let status: String
    let rulesVersion: Int
    let formulaVersion: Int
}

nonisolated struct RecommendedSports: Hashable, Sendable {
    let sportsName: String
    let sportsCategory: SportsCategory
    let matchRate: Int
}
