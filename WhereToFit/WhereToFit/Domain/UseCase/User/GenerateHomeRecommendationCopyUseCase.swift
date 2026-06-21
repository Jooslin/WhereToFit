//
//  GenerateHomeRecommendationCopyUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class GenerateHomeRecommendationCopyUseCase {
    private let repository: HomeRecommendationCopyRepositoryProtocol
    private let calendar: Calendar
    
    init(
        repository: HomeRecommendationCopyRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }
    
    func execute(
        profile: UserProfile,
        recommendedSports: [RecommendedSport]
    ) -> Single<HomeRecommendationCopy> {
        repository.generateCopy(
            profile: profile,
            recommendedSports: recommendedSports,
            ageGroup: Self.ageGroup(for: profile.birthDate, calendar: calendar)
        )
    }
}

private extension GenerateHomeRecommendationCopyUseCase {
    static func ageGroup(for birthDate: Date, calendar: Calendar) -> String {
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        switch age {
        case ..<7:
            return "아이"
        case 7..<13:
            return "어린이"
        case 13..<20:
            return "청소년"
        case 20..<30:
            return "20대"
        case 30..<40:
            return "30대"
        case 40..<50:
            return "40대"
        case 50..<60:
            return "50대"
        default:
            return "60대 이상"
        }
    }
}
