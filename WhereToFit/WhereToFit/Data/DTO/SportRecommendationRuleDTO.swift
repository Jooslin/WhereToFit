//
//  SportRecommendationRuleDTO.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation

nonisolated struct SportRecommendationRuleDTO: Decodable, Sendable {
    let id: Int
    let sportName: String
    let sportsCategory: String
    let ageWeights: [String: Int]
    let experienceWeights: [String: Int]
    let goalWeights: [String: Int]
    let bodyPartRiskWeights: [String: Int]
    let status: String
    let rulesVersion: Int
    let formulaVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case sportName = "sport_name"
        case sportsCategory = "sports_category"
        case ageWeights = "age_weights"
        case experienceWeights = "experience_weights"
        case goalWeights = "goal_weights"
        case bodyPartRiskWeights = "body_part_risk_weights"
        case status
        case rulesVersion = "rules_version"
        case formulaVersion = "formula_version"
    }
}

extension SportRecommendationRule {
    init(dto: SportRecommendationRuleDTO) {
        self.id = dto.id
        self.sportsName = dto.sportName
        self.sportsCategory = SportsCategory(rawValue: dto.sportsCategory) ?? .other
        self.ageWeights = dto.ageWeights
        self.experienceWeights = dto.experienceWeights
        self.goalWeights = dto.goalWeights
        self.bodyPartRiskWeights = dto.bodyPartRiskWeights
        self.status = dto.status
        self.rulesVersion = dto.rulesVersion
        self.formulaVersion = dto.formulaVersion
    }
}
