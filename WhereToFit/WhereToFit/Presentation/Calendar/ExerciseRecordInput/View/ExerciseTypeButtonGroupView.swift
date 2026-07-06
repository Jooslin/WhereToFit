//
//  ExerciseTypeButtonGroupView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ExerciseTypeButtonGroupView: UIView {
    fileprivate let customButton = ExerciseTypeButton(title: "기타 입력")
    fileprivate let registeredCategorySelectedRelay = PublishRelay<SportsCategory>()

    private let scrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private lazy var stackView = UIStackView(arrangedSubviews: [
        customButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
    }

    private var registeredCategoryButtons: [SportsCategory: ExerciseTypeButton] = [:]
    private var currentRegisteredCategories: [SportsCategory] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
        setButtonSize(customButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCategories(
        _ categories: [SportsCategory],
        selectedCategory: SportsCategory?
    ) {
        setCategories(categories)
        updateSelectedCategory(selectedCategory)
    }

    func updateSelectedCategory(_ selectedCategory: SportsCategory?) {
        registeredCategoryButtons.forEach { category, button in
            button.isSelected = category == selectedCategory
        }
    }

    func updateCustomButtonSelected(_ isSelected: Bool) {
        customButton.isSelected = isSelected
    }
}

private extension ExerciseTypeButtonGroupView {
    func setLayout() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    func setCategories(_ categories: [SportsCategory]) {
        guard currentRegisteredCategories != categories else { return }

        currentRegisteredCategories = categories
        registeredCategoryButtons.values.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        registeredCategoryButtons.removeAll()

        categories.forEach { category in
            let button = ExerciseTypeButton(title: category.rawValue)
            button.addAction(
                UIAction { [weak self] _ in
                    self?.registeredCategorySelectedRelay.accept(category)
                },
                for: .touchUpInside
            )
            stackView.addArrangedSubview(button)
            setButtonSize(button)
            registeredCategoryButtons[category] = button
        }
    }

    func setButtonSize(_ button: ExerciseTypeButton) {
        button.snp.makeConstraints {
            $0.width.equalTo(button.intrinsicContentSize.width)
            $0.height.equalTo(32)
        }
    }
}

extension Reactive where Base == ExerciseTypeButtonGroupView {
    var customButtonTap: ControlEvent<Void> {
        base.customButton.rx.controlEvent(.touchUpInside)
    }

    var registeredCategorySelected: ControlEvent<SportsCategory> {
        ControlEvent(events: base.registeredCategorySelectedRelay)
    }
}
