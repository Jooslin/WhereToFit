//
//  ExerciseRecordInputReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import Foundation
import ReactorKit
import RxSwift

final class ExerciseRecordInputReactor: Reactor {
    let initialState: State

    init(selectedDate: Date) {
        initialState = State(selectedDate: selectedDate)
    }

    struct DurationValue: Equatable {
        let hour: Int
        let minute: Int
        let second: Int

        var displayText: String {
            var components: [String] = []

            if hour > 0 {
                components.append("\(hour)시간")
            }

            if minute > 0 {
                components.append("\(minute)분")
            }

            if second > 0 {
                components.append("\(second)초")
            }

            return components.isEmpty ? "0분" : components.joined(separator: " ")
        }
    }

    enum Action {
        case customButtonTapped
        case durationFieldTapped
        case durationPickerChanged(DurationValue)
        case durationPickerSelectButtonTapped
    }

    enum Mutation {
        case setCustomInputVisible(Bool)
        case setDurationPickerVisible(Bool)
        case setSelectedDuration(DurationValue)
        case setConfirmedDuration(DurationValue)
    }

    struct State {
        var selectedDate: Date
        var isCustomInputVisible = false
        var isDurationPickerVisible = false
        var selectedDuration = DurationValue(hour: 0, minute: 0, second: 0)
        var confirmedDuration = DurationValue(hour: 0, minute: 0, second: 0)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .customButtonTapped:
            return .just(.setCustomInputVisible(!currentState.isCustomInputVisible))

        case .durationFieldTapped:
            return .just(.setDurationPickerVisible(true))

        case .durationPickerChanged(let duration):
            return .just(.setSelectedDuration(duration))

        case .durationPickerSelectButtonTapped:
            return .concat([
                .just(.setConfirmedDuration(currentState.selectedDuration)),
                .just(.setDurationPickerVisible(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setCustomInputVisible(let isVisible):
            newState.isCustomInputVisible = isVisible

        case .setDurationPickerVisible(let isVisible):
            newState.isDurationPickerVisible = isVisible

        case .setSelectedDuration(let duration):
            newState.selectedDuration = duration

        case .setConfirmedDuration(let duration):
            newState.confirmedDuration = duration
        }

        return newState
    }
}
