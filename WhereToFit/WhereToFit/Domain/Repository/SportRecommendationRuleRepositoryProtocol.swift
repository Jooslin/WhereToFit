//
//  SportRecommendationRuleRepositoryProtocol.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

protocol SportRecommendationRuleRepositoryProtocol {
    func fetchActiveRules() -> Single<[SportRecommendationRule]>
}
