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
        exerciseRecordInputView.rx.customButtonTap
            .map { ExerciseRecordInputReactor.Action.customButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseNameFieldTap
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

        exerciseRecordInputView.rx.exerciseSelectionResetButtonTap
            .map { ExerciseRecordInputReactor.Action.exerciseSelectionResetButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseSelectionApplyButtonTap
            .map { ExerciseRecordInputReactor.Action.exerciseSelectionApplyButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.exerciseSelectionCloseButtonTap
            .map { ExerciseRecordInputReactor.Action.exerciseSelectionCloseButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationFieldTap
            .map { ExerciseRecordInputReactor.Action.durationFieldTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationPickerChanged
            .map { ExerciseRecordInputReactor.Action.durationPickerChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.rx.durationPickerSelectButtonTap
            .map { ExerciseRecordInputReactor.Action.durationPickerSelectButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseRecordInputView.closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        exerciseRecordInputView.saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
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
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, state in
                owner.exerciseRecordInputView.updateExerciseNameSelection(
                    categories: state.exerciseCategories,
                    selectedCategory: state.selectedExerciseCategory,
                    sports: state.filteredExerciseSports,
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
    }
}
