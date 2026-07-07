//
//  ExerciseTypeButton.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import SnapKit
import UIKit

final class ExerciseTypeButton: UIControl {
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
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.textColor = .gray700
    }

    func setLayout() {
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14)
            $0.trailing.equalToSuperview().inset(14).priority(999)
            $0.centerY.equalToSuperview()
        }
    }
}
