//
//  HomeRecommendationCopyRepositoryProtocol.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

protocol HomeRecommendationCopyRepositoryProtocol {
    func generateCopy(
        profile: UserProfile,
        recommendedSports: [RecommendedSports],
        ageGroup: String
    ) -> Single<HomeRecommendationCopy>
}
