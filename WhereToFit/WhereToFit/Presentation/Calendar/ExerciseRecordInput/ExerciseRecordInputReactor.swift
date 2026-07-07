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
    private let fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase

    init(
        selectedDate: Date,
        saveExerciseRecordUseCase: SaveExerciseRecordUseCase,
        fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase
    ) {
        self.saveExerciseRecordUseCase = saveExerciseRecordUseCase
        self.fetchRegisteredProgramsUseCase = fetchRegisteredProgramsUseCase
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
        case viewDidLoad
        case customButtonTapped
        case registeredProgramCategorySelected(SportsCategory)
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
        case setRegisteredSportsCategories([SportsCategory])
        case setSelectedRegisteredSportsCategory(SportsCategory?)
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
        case setError(String, String)
    }

    struct State {
        var selectedDate: Date
        var isCustomInputVisible = false
        var registeredSportsCategories: [SportsCategory] = []
        var selectedRegisteredSportsCategory: SportsCategory?
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
        var isSaveButtonEnabled: Bool {
            appliedExerciseName?.isEmpty == false && confirmedDuration.timeInterval > 0
        }
        @Pulse var didSave: Bool?
        @Pulse var error: (String, String)?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchRegisteredProgramsUseCase.execute()
                .asObservable()
                .map { programs in
                    Self.uniqueSportsCategories(from: programs)
                }
                .map(Mutation.setRegisteredSportsCategories)

        case .customButtonTapped:
            return .concat([
                .just(.setSelectedRegisteredSportsCategory(nil)),
                .just(.setSelectedExerciseCategory(nil)),
                .just(.setSelectedExerciseSport(nil)),
                .just(.setAppliedExerciseName(nil)),
                .just(.setCustomInputVisible(!currentState.isCustomInputVisible))
            ])

        case .registeredProgramCategorySelected(let category):
            return .concat([
                .just(.setSelectedRegisteredSportsCategory(category)),
                .just(.setSelectedExerciseCategory(category)),
                .just(.setSelectedExerciseSport(nil)),
                .just(.setAppliedExerciseName(category.rawValue)),
                .just(.setExerciseSearchText("")),
                .just(.setExerciseSelectionVisible(false)),
                .just(.setCustomInputVisible(false))
            ])

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
            .catch { _ in
                .just(.setError("저장 실패", "운동 기록을 저장할 수 없습니다.\n잠시 후 다시 시도해주세요."))
            }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setRegisteredSportsCategories(let categories):
            newState.registeredSportsCategories = categories

        case .setSelectedRegisteredSportsCategory(let category):
            newState.selectedRegisteredSportsCategory = category

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

        case .setError(let title, let message):
            newState.error = (title, message)
        }

        return newState
    }
}

private extension ExerciseRecordInputReactor {
    static func uniqueSportsCategories(from programs: [RegisteredProgram]) -> [SportsCategory] {
        var seen = Set<SportsCategory>()

        return programs.compactMap(\.sportsCategory).filter { category in
            seen.insert(category).inserted
        }
    }
}
