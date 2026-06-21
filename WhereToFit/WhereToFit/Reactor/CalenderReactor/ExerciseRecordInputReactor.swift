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
    private let saveExerciseRecordUseCase: SaveExerciseRecordUseCase

    init(
        selectedDate: Date,
        saveExerciseRecordUseCase: SaveExerciseRecordUseCase
    ) {
        self.saveExerciseRecordUseCase = saveExerciseRecordUseCase
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

        var timeInterval: TimeInterval {
            TimeInterval(hour * 3600 + minute * 60 + second)
        }
    }

    enum Action {
        case customButtonTapped
        case exerciseNameFieldTapped
        case exerciseCategorySelected(SportsCategory)
        case exerciseSportSelected(String)
        case exerciseSearchTextChanged(String?)
        case exerciseSelectionApplyButtonTapped
        case exerciseSelectionCloseButtonTapped
        case durationFieldTapped
        case durationPickerChanged(DurationValue)
        case durationPickerSelectButtonTapped
        case durationPickerCloseButtonTapped
        case saveButtonTapped
    }

    enum Mutation {
        case setCustomInputVisible(Bool)
        case setExerciseSelectionVisible(Bool)
        case setSelectedExerciseCategory(SportsCategory?)
        case setSelectedExerciseSport(String?)
        case setAppliedExerciseName(String?)
        case setExerciseSearchText(String)
        case setDurationPickerVisible(Bool)
        case setSelectedDuration(DurationValue)
        case setConfirmedDuration(DurationValue)
        case setDidSave(Bool)
    }

    struct State {
        var selectedDate: Date
        var isCustomInputVisible = false
        var isExerciseSelectionVisible = false
        var exerciseCategories = SportsCategory.allCases
        var selectedExerciseCategory: SportsCategory?
        var selectedExerciseSport: String?
        var appliedExerciseName: String?
        var exerciseSearchText = ""
        var filteredExerciseSports: [String] {
            selectedExerciseCategory?.sports ?? []
        }
        var searchResults: [String] {
            guard !exerciseSearchText.isEmpty else { return [] }
            return SportsCategory.allCases
                .flatMap(\.sports)
                .filter { $0.localizedCaseInsensitiveContains(exerciseSearchText) }
        }
        var isDurationPickerVisible = false
        var selectedDuration = DurationValue(hour: 0, minute: 0, second: 0)
        var confirmedDuration = DurationValue(hour: 0, minute: 0, second: 0)
        @Pulse var didSave: Bool?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .customButtonTapped:
            return .just(.setCustomInputVisible(!currentState.isCustomInputVisible))

        case .exerciseNameFieldTapped:
            return .just(.setExerciseSelectionVisible(true))

        case .exerciseCategorySelected(let category):
            return .concat([
                .just(.setSelectedExerciseCategory(category)),
                .just(.setSelectedExerciseSport(nil)),
                .just(.setExerciseSearchText(""))
            ])

        case .exerciseSportSelected(let sport):
            let selectedCategory = SportsCategory(sport: sport)

            return .concat([
                .just(.setSelectedExerciseCategory(selectedCategory)),
                .just(.setSelectedExerciseSport(sport))
            ])

        case .exerciseSearchTextChanged(let text):
            let searchText = text ?? ""
            guard !searchText.isEmpty else {
                return .just(.setExerciseSearchText(searchText))
            }

            return .concat([
                .just(.setSelectedExerciseCategory(nil)),
                .just(.setExerciseSearchText(searchText))
            ])

        case .exerciseSelectionApplyButtonTapped:
            return .concat([
                .just(.setAppliedExerciseName(currentState.selectedExerciseSport)),
                .just(.setExerciseSelectionVisible(false))
            ])

        case .exerciseSelectionCloseButtonTapped:
            return .just(.setExerciseSelectionVisible(false))

        case .durationFieldTapped:
            return .just(.setDurationPickerVisible(true))

        case .durationPickerChanged(let duration):
            return .just(.setSelectedDuration(duration))

        case .durationPickerSelectButtonTapped:
            return .concat([
                .just(.setConfirmedDuration(currentState.selectedDuration)),
                .just(.setDurationPickerVisible(false))
            ])

        case .durationPickerCloseButtonTapped:
            return .just(.setDurationPickerVisible(false))

        case .saveButtonTapped:
            guard let exerciseName = currentState.appliedExerciseName,
                  currentState.confirmedDuration.timeInterval > 0 else {
                return .empty()
            }

            return saveExerciseRecordUseCase.execute(
                input: SaveExerciseRecordUseCase.Input(
                    date: currentState.selectedDate,
                    exerciseName: exerciseName,
                    sportsCategoryRawValue: currentState.selectedExerciseCategory?.rawValue,
                    duration: currentState.confirmedDuration.timeInterval,
                    calories: nil
                )
            )
            .asObservable()
            .map { _ in .setDidSave(true) }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setCustomInputVisible(let isVisible):
            newState.isCustomInputVisible = isVisible

        case .setExerciseSelectionVisible(let isVisible):
            newState.isExerciseSelectionVisible = isVisible

        case .setSelectedExerciseCategory(let category):
            newState.selectedExerciseCategory = category

        case .setSelectedExerciseSport(let sport):
            newState.selectedExerciseSport = sport

        case .setAppliedExerciseName(let name):
            newState.appliedExerciseName = name

        case .setExerciseSearchText(let text):
            newState.exerciseSearchText = text

        case .setDurationPickerVisible(let isVisible):
            newState.isDurationPickerVisible = isVisible

        case .setSelectedDuration(let duration):
            newState.selectedDuration = duration

        case .setConfirmedDuration(let duration):
            newState.confirmedDuration = duration

        case .setDidSave(let didSave):
            newState.didSave = didSave
        }

        return newState
    }
}
