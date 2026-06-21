//
//  ConditionInputView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import SnapKit
import Then
import UIKit

final class ConditionInputView: UIView {
    let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .gray600
    }

    let saveButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "저장하기"
    }

    let veryGoodButton = ConditionOptionButton(condition: .veryGood)
    let goodButton = ConditionOptionButton(condition: .good)
    let normalButton = ConditionOptionButton(condition: .normal)
    let badButton = ConditionOptionButton(condition: .bad)
    let worstButton = ConditionOptionButton(condition: .worst)

    private(set) var selectedCondition: CalendarReactor.ConditionValue

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

    private let titleLabel = UILabel(text: "컨디션 입력", config: .body14Medium)

    private lazy var firstRowStackView = UIStackView(arrangedSubviews: [
        veryGoodButton,
        goodButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.distribution = .fill
    }

    private lazy var secondRowStackView = UIStackView(arrangedSubviews: [
        normalButton,
        badButton,
        worstButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 14
        $0.distribution = .fill
    }

    init(currentCondition: CalendarReactor.ConditionValue) {
        selectedCondition = currentCondition

        super.init(frame: .zero)

        setStyle()
        setLayout()
        updateSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConditionInputView {
    func selectCondition(_ condition: CalendarReactor.ConditionValue) {
        selectedCondition = condition
        updateSelection()
    }
}

private extension ConditionInputView {
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
            firstRowStackView,
            secondRowStackView,
            saveButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(292)
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

        firstRowStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(22)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(116)
            $0.height.equalTo(48)
        }

        secondRowStackView.snp.makeConstraints {
            $0.top.equalTo(firstRowStackView.snp.bottom).offset(18)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
    }

    func updateSelection() {
        [
            veryGoodButton,
            goodButton,
            normalButton,
            badButton,
            worstButton
        ].forEach {
            $0.isSelected = $0.condition == selectedCondition
        }
    }
}

final class ConditionOptionButton: UIControl {
    let condition: CalendarReactor.ConditionValue

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .primary50
        $0.layer.cornerRadius = 18
        $0.clipsToBounds = true
    }

    private let titleLabel = UILabel(config: .body15, lines: 1).then {
        $0.lineBreakMode = .byClipping
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override var intrinsicContentSize: CGSize {
        let width = 6 + 36 + 12 + titleLabel.intrinsicContentSize.width + 10
        return CGSize(width: width, height: 48)
    }

    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .primary25 : .gray25
            titleLabel.textColor = isSelected ? .gray900 : .gray400
        }
    }

    init(condition: CalendarReactor.ConditionValue) {
        self.condition = condition
        super.init(frame: .zero)

        titleLabel.text = condition.displayText
        imageView.image = condition.image
        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConditionOptionButton {
    func setStyle() {
        backgroundColor = .white
        titleLabel.textColor = .gray400
        layer.cornerRadius = 24
    }

    func setLayout() {
        [
            imageView,
            titleLabel
        ].forEach(addSubview)

        imageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
    }
}
