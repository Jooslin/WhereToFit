//
//  CalendarReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxSwift

final class CalendarReactor: BaseReactor {
    let initialState = State(
        weight: WeightValue(integer: 54, decimal: 2),
        exerciseItems: [
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym),
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym),
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym)
        ]
    )

    enum ExerciseIcon: Equatable {
        case gym
    }

    struct WeightValue: Equatable {
        let integer: Int
        let decimal: Int

        var displayText: String {
            "\(integer).\(decimal)"
        }
    }

    struct ExerciseItem: Equatable {
        let title: String
        let duration: String
        let calories: String
        let icon: ExerciseIcon
    }

    enum Action {
        case updateWeight(WeightValue)
    }

    enum Mutation {
        case setWeight(WeightValue)
    }

    struct State {
        var weight: WeightValue
        var exerciseItems: [ExerciseItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateWeight(let weight):
            return .just(.setWeight(weight))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setWeight(let weight):
            newState.weight = weight
        }

        return newState
    }
}
