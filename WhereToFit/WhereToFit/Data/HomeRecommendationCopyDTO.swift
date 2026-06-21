//
//  HomeRecommendationCopyDTO.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation

nonisolated struct HomeRecommendationCopyRequestDTO: Encodable, Sendable {
    let ageGroup: String
    let exerciseGoal: String
    let exerciseExperience: String
    let recommendedSports: [RecommendedSportDTO]
    
    enum CodingKeys: String, CodingKey {
        case ageGroup = "age_group"
        case exerciseGoal = "exercise_goal"
        case exerciseExperience = "exercise_experience"
        case recommendedSports = "recommended_sports"
    }
}

nonisolated struct RecommendedSportDTO: Encodable, Sendable {
    let sportName: String
    let sportsCategory: String
    let matchRate: Int
    
    enum CodingKeys: String, CodingKey {
        case sportName = "sport_name"
        case sportsCategory = "sports_category"
        case matchRate = "match_rate"
    }
}

nonisolated struct HomeRecommendationCopyResponseDTO: Decodable, Sendable {
    let categoryTitle: String
    let personalizedReason: String
    
    enum CodingKeys: String, CodingKey {
        case categoryTitle = "category_title"
        case personalizedReason = "personalized_reason"
    }
}

extension HomeRecommendationCopy {
    init(dto: HomeRecommendationCopyResponseDTO) {
        self.categoryTitle = Self.normalizedCategoryTitle(dto.categoryTitle)
        self.personalizedReason = dto.personalizedReason
    }
    
    private static func normalizedCategoryTitle(_ title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let ageGroups = ["아이", "어린이", "청소년", "20대", "30대", "40대", "50대", "60대 이상"]
        
        for ageGroup in ageGroups where trimmedTitle.hasPrefix(ageGroup) {
            let suffix = trimmedTitle
                .dropFirst(ageGroup.count)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard suffix.isEmpty == false else { return ageGroup }
            return "\(ageGroup) \(suffix)"
        }
        
        return trimmedTitle
    }
}
