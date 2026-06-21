//
//  ExerciseResultReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxSwift

final class ExerciseResultReactor: BaseReactor {
    let initialState = State(
        summaryItems: [
            SummaryItem(title: "운동 경험", value: "미입력"),
            SummaryItem(title: "운동 목표", value: "미입력"),
            SummaryItem(title: "운동 선호", value: "미입력"),
            SummaryItem(title: "불편한 신체부위", value: "미입력")
        ],
        recommendationItems: [
            RecommendationItem(title: "저녁 요가", tags: ["초급", "실내"], icon: .aquaticSports),
            RecommendationItem(title: "체조", tags: ["초급", "야외"], icon: .aquaticSports),
            RecommendationItem(title: "초급 수영", tags: ["초급", "실내"], icon: .aquaticSports)
        ]
    )
    private let fetchUserProfileUseCase: FetchUserProfileUseCase

    init(fetchUserProfileUseCase: FetchUserProfileUseCase) {
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
    }

    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setSummaryItems([SummaryItem])
    }

    enum RecommendationIcon: Equatable {
        case aquaticSports
    }

    struct SummaryItem: Equatable {
        let title: String
        let value: String
    }

    struct RecommendationItem: Equatable {
        let title: String
        let tags: [String]
        let icon: RecommendationIcon
    }

    struct State {
        var summaryItems: [SummaryItem]
        var recommendationItems: [RecommendationItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchUserProfileUseCase.execute()
                .asObservable()
                .compactMap { $0 }
                .map { Mutation.setSummaryItems(Self.makeSummaryItems(from: $0)) }
                .catch { _ in .empty() }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSummaryItems(let items):
            newState.summaryItems = items
        }

        return newState
    }
}

private extension ExerciseResultReactor {
    static func makeSummaryItems(from profile: UserProfile) -> [SummaryItem] {
        [
            SummaryItem(title: "운동 경험", value: profile.exerciseExperience?.rawValue ?? "미입력"),
            SummaryItem(title: "운동 목표", value: profile.exerciseGoal?.rawValue ?? "미입력"),
            SummaryItem(title: "운동 선호", value: displayText(profile.preferredSportsCategories.map(\.rawValue))),
            SummaryItem(title: "불편한 신체부위", value: displayText(profile.discomfortBodyParts.map(\.rawValue)))
        ]
    }

    static func displayText(_ values: [String]) -> String {
        values.isEmpty ? "미입력" : values.joined(separator: " / ")
    }
}
