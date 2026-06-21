//
//  ExerciseRecordInputView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ExerciseRecordInputView: UIView {
    let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .gray600
    }

    let saveButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "저장하기"
    }

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }
    fileprivate let swipeDismissRelay = PublishRelay<Void>()
    private var swipeDismissHandler: BottomSheetSwipeDismissHandler?

    private let sheetView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray200
        $0.layer.cornerRadius = 2
    }

    private let titleLabel = UILabel(text: "운동 기록", config: .body14Medium)

    fileprivate let exerciseTypeButtonGroupView = ExerciseTypeButtonGroupView()
    fileprivate let exerciseNameField = ExerciseRecordField(title: "운동 종목", placeholder: "운동 종목을 선택해주세요")
    private let dateField = ExerciseRecordField(title: "날짜")
    fileprivate let durationField = ExerciseRecordField(title: "운동한 시간", text: "0분")
    fileprivate let exerciseNameSelectionSheetView = ExerciseNameSelectionSheetView()
    fileprivate let durationPickerSheetView = DurationPickerSheetView()

    private lazy var fieldStackView = UIStackView(arrangedSubviews: [
        exerciseNameField,
        dateField,
        durationField
    ]).then {
        $0.axis = .vertical
        $0.spacing = 16
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
        setExerciseNameSelectionSheet()
        setDurationPicker()
        setDateField()
        setCustomInputVisible(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExerciseRecordInputView {
    func updateDate(_ dateText: String) {
        dateField.text = dateText
    }

    func updateCustomInputVisible(_ isVisible: Bool) {
        setCustomInputVisible(isVisible, animated: true)
    }

    func updateRegisteredSportsCategories(
        _ categories: [SportsCategory],
        selectedCategory: SportsCategory?
    ) {
        exerciseTypeButtonGroupView.updateCategories(categories, selectedCategory: selectedCategory)
    }

    func updateSelectedRegisteredSportsCategory(_ selectedCategory: SportsCategory?) {
        exerciseTypeButtonGroupView.updateSelectedCategory(selectedCategory)
    }

    func updateExerciseNameSelectionVisible(_ isVisible: Bool) {
        if isVisible {
            showExerciseNameSelection()
        } else {
            hideExerciseNameSelection()
        }
    }

    func updateExerciseNameSelection(
        categories: [SportsCategory],
        selectedCategory: SportsCategory?,
        sports: [String],
        searchResults: [String],
        selectedSport: String?,
        searchText: String
    ) {
        exerciseNameSelectionSheetView.update(
            categories: categories,
            selectedCategory: selectedCategory,
            sports: sports,
            searchResults: searchResults,
            selectedSport: selectedSport,
            searchText: searchText
        )
    }

    func updateExerciseName(_ exerciseName: String?) {
        exerciseNameField.text = exerciseName
    }

    func updateDurationPickerVisible(_ isVisible: Bool) {
        if isVisible {
            showDurationPicker()
        } else {
            hideDurationPicker()
        }
    }

    func updateSelectedDuration(_ duration: ExerciseRecordInputReactor.DurationValue) {
        durationPickerSheetView.updateSelectedDuration(duration)
    }

    func updateConfirmedDuration(_ duration: ExerciseRecordInputReactor.DurationValue) {
        durationField.text = duration.displayText
    }
}

private extension ExerciseRecordInputView {
    func setStyle() {
        backgroundColor = .clear
        swipeDismissHandler = BottomSheetSwipeDismissHandler(sheetView: sheetView)
        swipeDismissHandler?.onDismiss = { [weak self] in
            self?.swipeDismissRelay.accept(())
        }
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            handleView,
            titleLabel,
            closeButton,
            exerciseTypeButtonGroupView,
            fieldStackView,
            saveButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.equalToSuperview().offset(16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        exerciseTypeButtonGroupView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.height.equalTo(32)
        }

        fieldStackView.snp.makeConstraints {
            $0.top.equalTo(exerciseTypeButtonGroupView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(fieldStackView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setCustomInputVisible(_ isVisible: Bool, animated: Bool = false) {
        exerciseTypeButtonGroupView.updateCustomButtonSelected(isVisible)
        exerciseNameField.isHidden = !isVisible

        guard animated else {
            layoutIfNeeded()
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    func setExerciseNameSelectionSheet() {
        exerciseNameSelectionSheetView.alpha = 0
        exerciseNameSelectionSheetView.isHidden = true
        exerciseNameField.setReadOnly()
    }

    func setDurationPicker() {
        durationPickerSheetView.alpha = 0
        durationPickerSheetView.isHidden = true
        durationField.setReadOnly()
    }

    func setDateField() {
        dateField.setReadOnly()
        dateField.isUserInteractionEnabled = false
    }

    func showExerciseNameSelection() {
        endEditing(true)
        guard exerciseNameSelectionSheetView.superview == nil else { return }

        addSubview(exerciseNameSelectionSheetView)
        exerciseNameSelectionSheetView.alpha = 0
        exerciseNameSelectionSheetView.isHidden = false
        exerciseNameSelectionSheetView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layoutIfNeeded()

        UIView.animate(withDuration: 0.25) {
            self.exerciseNameSelectionSheetView.alpha = 1
        }
    }

    func hideExerciseNameSelection() {
        guard exerciseNameSelectionSheetView.superview != nil else { return }

        UIView.animate(withDuration: 0.25) {
            self.exerciseNameSelectionSheetView.alpha = 0
        } completion: { _ in
            self.exerciseNameSelectionSheetView.isHidden = true
            self.exerciseNameSelectionSheetView.removeFromSuperview()
        }
    }

    func showDurationPicker() {
        endEditing(true)
        guard durationPickerSheetView.superview == nil else { return }

        addSubview(durationPickerSheetView)
        durationPickerSheetView.alpha = 0
        durationPickerSheetView.isHidden = false
        durationPickerSheetView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layoutIfNeeded()

        UIView.animate(withDuration: 0.25) {
            self.durationPickerSheetView.alpha = 1
        }
    }

    func hideDurationPicker() {
        guard durationPickerSheetView.superview != nil else { return }

        UIView.animate(withDuration: 0.25) {
            self.durationPickerSheetView.alpha = 0
        } completion: { _ in
            self.durationPickerSheetView.isHidden = true
            self.durationPickerSheetView.removeFromSuperview()
        }
    }
}

extension Reactive where Base == ExerciseRecordInputView {
    var customButtonTap: ControlEvent<Void> {
        base.exerciseTypeButtonGroupView.rx.customButtonTap
    }

    var registeredProgramCategorySelected: ControlEvent<SportsCategory> {
        base.exerciseTypeButtonGroupView.rx.registeredCategorySelected
    }

    var exerciseNameFieldTap: ControlEvent<Void> {
        base.exerciseNameField.rx.editingDidBegin
    }

    var exerciseNameSearchText: ControlProperty<String?> {
        base.exerciseNameSelectionSheetView.rx.searchText
    }

    var exerciseCategorySelected: ControlEvent<SportsCategory> {
        base.exerciseNameSelectionSheetView.rx.categorySelected
    }

    var exerciseSportSelected: ControlEvent<String> {
        base.exerciseNameSelectionSheetView.rx.sportSelected
    }

    var exerciseSelectionApplyButtonTap: ControlEvent<Void> {
        base.exerciseNameSelectionSheetView.applyButton.rx.tap
    }

    var exerciseSelectionCloseButtonTap: ControlEvent<Void> {
        base.exerciseNameSelectionSheetView.closeButton.rx.tap
    }

    var durationFieldTap: ControlEvent<Void> {
        base.durationField.rx.editingDidBegin
    }

    var durationPickerSelectButtonTap: ControlEvent<Void> {
        base.durationPickerSheetView.selectButton.rx.tap
    }

    var durationPickerCloseButtonTap: ControlEvent<Void> {
        base.durationPickerSheetView.closeButton.rx.tap
    }

    var durationPickerChanged: ControlEvent<ExerciseRecordInputReactor.DurationValue> {
        base.durationPickerSheetView.rx.durationChanged
    }

    var swipeDownToDismiss: ControlEvent<Void> {
        ControlEvent(events: base.swipeDismissRelay)
    }
}
