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
        selectedDate: CalendarReactor.normalizedDate(Date()),
        weight: nil,
        condition: nil,
        exerciseItems: [
            ExerciseItem(title: "수영", duration: "120분", calories: "210칼로리", sportsCategory: .aquaticSports),
            ExerciseItem(title: "요가", duration: "30분", calories: "120칼로리", sportsCategory: .yogaPilates),
            ExerciseItem(title: "풋살", duration: "58분", calories: "187칼로리", sportsCategory: .ballSports)
        ]
    )

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
        let sportsCategory: SportsCategory
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
        var weight: WeightValue?
        var condition: ConditionValue?
        var exerciseItems: [ExerciseItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectDate(let date):
            return .just(.setSelectedDate(Self.normalizedDate(date)))
        case .moveToToday:
            return .just(.setSelectedDate(Self.normalizedDate(Date())))
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

    private static func normalizedDate(_ date: Date) -> Date {
        Calendar(identifier: .gregorian).startOfDay(for: date)
    }
}
