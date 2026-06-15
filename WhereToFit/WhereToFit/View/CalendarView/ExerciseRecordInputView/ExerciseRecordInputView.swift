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

    fileprivate let customButton = ExerciseTypeButton(title: "기타 입력")

    private lazy var exerciseTypeStackView = UIStackView(arrangedSubviews: [
        customButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fill
    }

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

    func updateExerciseNameSelectionVisible(_ isVisible: Bool) {
        if isVisible {
            showExerciseNameSelection()
        } else {
            hideExerciseNameSelection()
        }
    }

    func updateExerciseNameSelection(
        categories: [SportsCategory],
        selectedCategory: SportsCategory,
        sports: [String],
        selectedSport: String?,
        searchText: String
    ) {
        exerciseNameSelectionSheetView.update(
            categories: categories,
            selectedCategory: selectedCategory,
            sports: sports,
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
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)
        addSubview(exerciseNameSelectionSheetView)
        addSubview(durationPickerSheetView)

        [
            handleView,
            titleLabel,
            closeButton,
            exerciseTypeStackView,
            fieldStackView,
            saveButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        durationPickerSheetView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        exerciseNameSelectionSheetView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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

        exerciseTypeStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        fieldStackView.snp.makeConstraints {
            $0.top.equalTo(exerciseTypeStackView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(fieldStackView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setCustomInputVisible(_ isVisible: Bool, animated: Bool = false) {
        customButton.isSelected = isVisible
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

    func showExerciseNameSelection() {
        endEditing(true)
        guard exerciseNameSelectionSheetView.isHidden else { return }

        exerciseNameSelectionSheetView.isHidden = false

        UIView.animate(withDuration: 0.25) {
            self.exerciseNameSelectionSheetView.alpha = 1
        }
    }

    func hideExerciseNameSelection() {
        guard !exerciseNameSelectionSheetView.isHidden else { return }

        UIView.animate(withDuration: 0.25) {
            self.exerciseNameSelectionSheetView.alpha = 0
        } completion: { _ in
            self.exerciseNameSelectionSheetView.isHidden = true
        }
    }

    func showDurationPicker() {
        endEditing(true)
        guard durationPickerSheetView.isHidden else { return }

        durationPickerSheetView.isHidden = false

        UIView.animate(withDuration: 0.25) {
            self.durationPickerSheetView.alpha = 1
        }
    }

    func hideDurationPicker() {
        guard !durationPickerSheetView.isHidden else { return }

        UIView.animate(withDuration: 0.25) {
            self.durationPickerSheetView.alpha = 0
        } completion: { _ in
            self.durationPickerSheetView.isHidden = true
        }
    }
}

extension Reactive where Base == ExerciseRecordInputView {
    var customButtonTap: ControlEvent<Void> {
        base.customButton.rx.controlEvent(.touchUpInside)
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

    var exerciseSelectionResetButtonTap: ControlEvent<Void> {
        base.exerciseNameSelectionSheetView.resetButton.rx.tap
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

    var durationPickerChanged: ControlEvent<ExerciseRecordInputReactor.DurationValue> {
        base.durationPickerSheetView.rx.durationChanged
    }
}

private final class ExerciseTypeButton: UIControl {
    private let titleLabel = UILabel(config: .body13Medium)

    override var intrinsicContentSize: CGSize {
        CGSize(width: titleLabel.intrinsicContentSize.width + 28, height: 32)
    }

    override var isSelected: Bool {
        didSet {
            layer.borderColor = isSelected ? UIColor.primary400.cgColor : UIColor.gray200.cgColor
            titleLabel.textColor = isSelected ? .primary400 : .gray700
        }
    }

    init(title: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ExerciseTypeButton {
    func setStyle() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray200.cgColor
        titleLabel.textColor = .gray700
    }

    func setLayout() {
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }
    }
}

fileprivate final class ExerciseRecordField: UIView {
    private let titleLabel: UILabel
    fileprivate let textField = DesignTextField().then {
        $0.font = LabelConfiguration.body14Medium.font
    }

    var text: String? {
        get {
            textField.text
        }
        set {
            textField.text = newValue
        }
    }

    init(title: String, text: String? = nil, placeholder: String? = nil) {
        titleLabel = UILabel(text: title, config: .body14Medium, color: .gray700)

        super.init(frame: .zero)

        textField.text = text
        if let placeholder {
            textField.setPlaceholder(text: placeholder)
        }

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate extension ExerciseRecordField {
    func setReadOnly() {
        textField.inputView = UIView()
        textField.tintColor = .clear
    }

    func setLayout() {
        [
            titleLabel,
            textField
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(48)
        }
    }
}

extension Reactive where Base == ExerciseRecordField {
    var editingDidBegin: ControlEvent<Void> {
        base.textField.rx.controlEvent(.editingDidBegin)
    }
}
