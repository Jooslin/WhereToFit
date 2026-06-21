//
//  PreloadSportRecommendationRulesUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class PreloadSportRecommendationRulesUseCase {
    private let repository: SportRecommendationRuleRepositoryProtocol
    
    init(repository: SportRecommendationRuleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() -> Single<Void> {
        repository.fetchActiveRules()
            .map { _ in () }
    }
}
