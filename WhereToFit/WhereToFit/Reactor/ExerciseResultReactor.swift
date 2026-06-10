//
//  ExerciseResultReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import UIKit

final class ExerciseResultReactor: BaseReactor {
    let initialState = State(
        summaryItems: [
            SummaryItem(title: "운동 목적", value: "건강 관리"),
            SummaryItem(title: "선호 운동", value: "걷기 / 요가"),
            SummaryItem(title: "선호 시간", value: "저녁"),
            SummaryItem(title: "운동 강도", value: "초급")
        ],
        recommendationItems: [
            RecommendationItem(title: "저녁 요가", tags: ["초급", "실내"], image: UIImage(resource: .aquaticSports)),
            RecommendationItem(title: "체조", tags: ["초급", "야외"], image: UIImage(resource: .aquaticSports)),
            RecommendationItem(title: "초급 수영", tags: ["초급", "실내"], image: UIImage(resource: .aquaticSports))
        ]
    )

    enum Action {}

    struct SummaryItem: Equatable {
        let title: String
        let value: String
    }

    struct RecommendationItem: Equatable {
        let title: String
        let tags: [String]
        let image: UIImage
    }

    struct State {
        var summaryItems: [SummaryItem]
        var recommendationItems: [RecommendationItem]
    }
}
