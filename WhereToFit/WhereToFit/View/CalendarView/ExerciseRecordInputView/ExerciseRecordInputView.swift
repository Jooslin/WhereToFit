//
//  ExerciseRecordInputView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

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

    private let swimmingButton = ExerciseTypeButton(title: "수영")
    private let pilatesButton = ExerciseTypeButton(title: "필라테스")
    private let yogaButton = ExerciseTypeButton(title: "요가")
    private let customButton = ExerciseTypeButton(title: "기타 입력")

    private lazy var exerciseTypeStackView = UIStackView(arrangedSubviews: [
        swimmingButton,
        pilatesButton,
        yogaButton,
        customButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fill
    }

    private let exerciseNameField = ExerciseRecordField(title: "운동 종목", placeholder: "운동 종목을 선택해주세요")
    private let dateField = ExerciseRecordField(title: "날짜", text: "2026.05.18")
    private let durationField = ExerciseRecordField(title: "운동한 시간", text: "30분")

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
        customButton.isSelected = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ExerciseRecordInputView {
    func setStyle() {
        backgroundColor = .clear
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            handleView,
            titleLabel,
            closeButton,
            exerciseTypeStackView,
            exerciseNameField,
            dateField,
            durationField,
            saveButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(465)
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(38)
            $0.leading.equalToSuperview().offset(16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        exerciseTypeStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        exerciseNameField.snp.makeConstraints {
            $0.top.equalTo(exerciseTypeStackView.snp.bottom).offset(18)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        dateField.snp.makeConstraints {
            $0.top.equalTo(exerciseNameField.snp.bottom).offset(22)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        durationField.snp.makeConstraints {
            $0.top.equalTo(dateField.snp.bottom).offset(22)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
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

private final class ExerciseRecordField: UIView {
    private let titleLabel: UILabel
    private let textField = DesignTextField().then {
        $0.font = LabelConfiguration.body14Medium.font
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

private extension ExerciseRecordField {
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
