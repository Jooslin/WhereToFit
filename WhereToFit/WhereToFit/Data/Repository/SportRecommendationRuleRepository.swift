//
//  SportRecommendationRuleRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class SportRecommendationRuleRepository: SportRecommendationRuleRepositoryProtocol {
    private static let cacheLock = NSLock()
    private static var cachedActiveRules: [SportRecommendationRule]?
    
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchActiveRules() -> Single<[SportRecommendationRule]> {
        if let cachedRules = Self.cachedRules() {
            return .just(cachedRules)
        }
        
        return Single.async { [networkService] in
            let page: SupabasePage<SportRecommendationRuleDTO> = try await networkService.fetchSupabaseData(
                api: .sportRecommendationRules,
                filters: ["status": "eq.active"],
                limit: 200,
                offset: 0,
                order: .ascending
            )
            
            let rules = page.items.map(SportRecommendationRule.init)
            Self.storeCachedRules(rules)
            return rules
        }
    }
}

private extension SportRecommendationRuleRepository {
    static func cachedRules() -> [SportRecommendationRule]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        return cachedActiveRules
    }
    
    static func storeCachedRules(_ rules: [SportRecommendationRule]) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        cachedActiveRules = rules
    }
}
