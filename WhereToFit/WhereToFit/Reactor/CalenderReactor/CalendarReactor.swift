//
//  CalendarReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import Foundation
import ReactorKit
import RxSwift

final class CalendarReactor: BaseReactor {
    let initialState = State(
        selectedDate: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 5, day: 18).date ?? Date(),
        weight: WeightValue(integer: 54, decimal: 2),
        condition: .worst,
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

    enum ConditionValue: CaseIterable, Equatable {
        case veryGood
        case good
        case normal
        case bad
        case worst

        var displayText: String {
            switch self {
            case .veryGood:
                return "매우 좋음"
            case .good:
                return "좋음"
            case .normal:
                return "보통"
            case .bad:
                return "안좋음"
            case .worst:
                return "최악"
            }
        }
    }

    struct ExerciseItem: Equatable {
        let title: String
        let duration: String
        let calories: String
        let icon: ExerciseIcon
    }

    enum Action {
        case selectDate(Date)
        case moveToToday
        case updateWeight(WeightValue)
        case updateCondition(ConditionValue)
    }

    enum Mutation {
        case setSelectedDate(Date)
        case setWeight(WeightValue)
        case setCondition(ConditionValue)
    }

    struct State {
        var selectedDate: Date
        var weight: WeightValue
        var condition: ConditionValue
        var exerciseItems: [ExerciseItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectDate(let date):
            return .just(.setSelectedDate(date))
        case .moveToToday:
            return .just(.setSelectedDate(Date()))
        case .updateWeight(let weight):
            return .just(.setWeight(weight))
        case .updateCondition(let condition):
            return .just(.setCondition(condition))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedDate(let date):
            newState.selectedDate = date
        case .setWeight(let weight):
            newState.weight = weight
        case .setCondition(let condition):
            newState.condition = condition
        }

        return newState
    }
}
