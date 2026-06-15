//
//  CalendarInfoCardView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import SnapKit
import UIKit

final class CalendarInfoCardView: UIControl {
    private let titleLabel: UILabel
    private let valueLabel: UILabel
    private let unitLabel: UILabel?

    init(title: String, value: String, unit: String?) {
        titleLabel = UILabel(text: title, config: .body12Medium, color: .gray500)
        valueLabel = UILabel(text: value, config: .title24)
        unitLabel = unit.map { UILabel(text: $0, config: .body12Medium, color: .gray500) }

        super.init(frame: .zero)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarInfoCardView {
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}

private extension CalendarInfoCardView {
    func setStyle() {
        backgroundColor = .gray50
        layer.cornerRadius = 12
    }

    func setLayout() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        if let unitLabel {
            addSubview(unitLabel)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        valueLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().inset(12)
        }

        unitLabel?.snp.makeConstraints {
            $0.leading.equalTo(valueLabel.snp.trailing).offset(6)
            $0.lastBaseline.equalTo(valueLabel)
        }
    }
}
