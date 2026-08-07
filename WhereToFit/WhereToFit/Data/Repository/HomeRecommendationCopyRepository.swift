//
//  HomeRecommendationCopyRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class HomeRecommendationCopyRepository: HomeRecommendationCopyRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func generateCopy(
        profile: UserProfile,
        recommendedSports: [RecommendedSport],
        ageGroup: String
    ) -> Single<HomeRecommendationCopy> {
        let request = HomeRecommendationCopyRequestDTO(
            ageGroup: ageGroup,
            exerciseGoal: profile.exerciseGoal?.rawValue ?? "건강 관리",
            exerciseExperience: profile.exerciseExperience?.rawValue ?? "초보",
            recommendedSports: recommendedSports.map {
                RecommendedSportDTO(
                    sportName: $0.sportsName,
                    sportsCategory: $0.sportsCategory.rawValue,
                    matchRate: $0.matchRate
                )
            }
        )
        
        return Single.async { [networkService] in
            let response: HomeRecommendationCopyResponseDTO = try await networkService.invokeSupabaseFunction(
                name: "generate-home-recommendation-copy",
                body: request
            )
            
            return HomeRecommendationCopy(dto: response)
        }
    }
}
