//
//  CalendarInfoCardView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import SnapKit
import Then
import UIKit

final class CalendarInfoCardView: UIControl {
    private let titleLabel: UILabel
    private let valueImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
    }
    private let valueLabel: UILabel
    private let unitLabel: UILabel?
    private lazy var valueStackView = UIStackView(arrangedSubviews: makeValueArrangedSubviews()).then {
        $0.axis = .horizontal
        $0.alignment = .lastBaseline
        $0.spacing = 8
    }

    init(title: String, value: String, unit: String?, valueImage: UIImage? = nil) {
        titleLabel = UILabel(text: title, config: .body12Medium, color: .gray500)
        valueLabel = UILabel(text: value, config: .title24)
        unitLabel = unit.map { UILabel(text: $0, config: .body12Medium, color: .gray500) }
        valueImageView.image = valueImage
        valueImageView.isHidden = valueImage == nil

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

    func updateValueImage(_ image: UIImage?) {
        valueImageView.image = image
        valueImageView.isHidden = image == nil
    }
}

private extension CalendarInfoCardView {
    func setStyle() {
        backgroundColor = .gray25
        layer.cornerRadius = 12
    }

    func setLayout() {
        addSubview(titleLabel)
        addSubview(valueStackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        valueImageView.snp.makeConstraints {
            $0.size.equalTo(28)
        }

        valueStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    func makeValueArrangedSubviews() -> [UIView] {
        if let unitLabel {
            return [valueImageView, valueLabel, unitLabel]
        }

        return [valueImageView, valueLabel]
    }
}
