//
//  MapFilterView.swift
//  WhereToFit
//
//  Created by 김주희 on 6/8/26.
//

import UIKit
import SnapKit
import Then

final class MapFilterView: UIView {
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    let contentView = UIView()

    let sectionStackView = UIStackView().then {
        $0.axis = .vertical
    }

    let closeButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(resource: .close).withTintColor(.gray600, renderingMode: .alwaysOriginal), for: .normal)
    }

    let resetButton = DesignButton(config: .mediumBorderBlue).then {
        $0.title = "초기화"
    }

    let applyButton = DesignButton(config: .mediumFilledBlue).then {
        $0.title = "적용"
    }

    let minimumPriceTextField: UITextField = PriceTextField(placeholder: "20,000 원")
    let maximumPriceTextField: UITextField = PriceTextField(placeholder: "300,000 원")

    let categorySearchTextField = SearchBar(placeholder: "하고 싶은 운동 종목 입력")

    let bottomActionView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayout() {
        addSubview(scrollView)
        addSubview(bottomActionView)
        addSubview(closeButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(sectionStackView)
        bottomActionView.addSubview(resetButton)
        bottomActionView.addSubview(applyButton)

        closeButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(28)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        bottomActionView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(84)
        }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(12)
            $0.height.equalTo(48)
            $0.width.equalTo(applyButton)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalTo(resetButton.snp.trailing).offset(14)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.height.equalTo(resetButton)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(32)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomActionView.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        sectionStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

private final class PriceTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        keyboardType = .numberPad
        font = LabelConfiguration.body13Regular.font
        textColor = .gray900
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray200.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 16, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 16, dy: 0)
    }
}
