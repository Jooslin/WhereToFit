//
//  ExerciseRecordInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class ExerciseRecordInputViewController: BaseViewController<ExerciseRecordInputReactor> {
    private let exerciseRecordInputView = ExerciseRecordInputView()
    var onSave: (() -> Void)?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    override func loadView() {
        view = exerciseRecordInputView
    }
    
    override func bind(reactor: ExerciseRecordInputReactor) {
        Observable.just(())
            .map { ExerciseRecordInputReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.customButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.customButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.registeredProgramCategorySelected
            .map { ExerciseRecordInputReactor.Action.registeredProgramCategorySelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseNameFieldTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.exerciseNameFieldTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseNameSearchText
            .skip(1)
            .map { ExerciseRecordInputReactor.Action.exerciseSearchTextChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseCategorySelected
            .map { ExerciseRecordInputReactor.Action.exerciseCategorySelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseSportSelected
            .map { ExerciseRecordInputReactor.Action.exerciseSportSelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseSelectionApplyButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.exerciseSelectionApplyButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseSelectionCloseButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.exerciseSelectionCloseButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationFieldTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.durationFieldTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationPickerChanged
            .map { ExerciseRecordInputReactor.Action.durationPickerChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationPickerSelectButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.durationPickerSelectButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationPickerCloseButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.durationPickerCloseButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.closeButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.swipeDownToDismiss
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        exerciseRecordInputView.saveButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ExerciseRecordInputReactor.Action.saveButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isSaveButtonEnabled)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: exerciseRecordInputView.saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedDate)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, selectedDate in
                owner.exerciseRecordInputView.updateDate(owner.dateFormatter.string(from: selectedDate))
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isCustomInputVisible)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, isVisible in
                owner.exerciseRecordInputView.updateCustomInputVisible(isVisible)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.registeredSportsCategories)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, categories in
                owner.exerciseRecordInputView.updateRegisteredSportsCategories(
                    categories,
                    selectedCategory: reactor.currentState.selectedRegisteredSportsCategory
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedRegisteredSportsCategory)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, selectedCategory in
                owner.exerciseRecordInputView.updateSelectedRegisteredSportsCategory(selectedCategory)
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, state in
                owner.exerciseRecordInputView.updateExerciseNameSelection(
                    categories: state.exerciseCategories,
                    selectedCategory: state.selectedExerciseCategory,
                    sports: state.filteredExerciseSports,
                    searchResults: state.searchResults,
                    selectedSport: state.selectedExerciseSport,
                    searchText: state.exerciseSearchText
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isExerciseSelectionVisible)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, isVisible in
                owner.exerciseRecordInputView.updateExerciseNameSelectionVisible(isVisible)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.appliedExerciseName)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, exerciseName in
                owner.exerciseRecordInputView.updateExerciseName(exerciseName)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isDurationPickerVisible)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, isVisible in
                owner.exerciseRecordInputView.updateDurationPickerVisible(isVisible)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedDuration)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, duration in
                owner.exerciseRecordInputView.updateSelectedDuration(duration)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.confirmedDuration)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, duration in
                owner.exerciseRecordInputView.updateConfirmedDuration(duration)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$didSave)
            .compactMap { $0 }
            .filter { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.onSave?()
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$error)
            .compactMap { $0 }
            .map { AppStep.alert(title: $0.0, message: $0.1) }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}
