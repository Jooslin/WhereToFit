//
//  SportRecommendationRuleRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class SportRecommendationRuleRepository: SportRecommendationRuleRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchActiveRules() -> Single<[SportRecommendationRule]> {
        Single.async { [networkService] in
            let page: SupabasePage<SportRecommendationRuleDTO> = try await networkService.fetchSupabaseData(
                api: .sportRecommendationRules,
                filters: ["status": "eq.active"],
                limit: 200,
                offset: 0,
                order: .ascending
            )
            
            return page.items.map(SportRecommendationRule.init)
        }
    }
}
