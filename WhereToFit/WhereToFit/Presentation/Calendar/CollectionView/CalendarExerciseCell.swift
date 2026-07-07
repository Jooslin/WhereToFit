//
//  CalendarExerciseCell.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/11/26.
//

import SnapKit
import Then
import UIKit

final class CalendarExerciseCell: UICollectionViewCell {
    static let reuseIdentifier = "CalendarExerciseCell"

    private let iconView = RoundImageView(image: UIImage(resource: .gym), type: .roundSquare)
    private let titleLabel = UILabel(config: .body14Medium)
    private let timeLabel = UILabel(config: .body12Regular, color: .gray500)
    private let calorieLabel = UILabel(config: .body12Medium, color: .gray500)
    private let divider = UIView().then {
        $0.backgroundColor = .gray100
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarExerciseCell {
    func configure(item: CalendarReactor.ExerciseItem, hidesDivider: Bool) {
        let category = item.sportsCategoryRawValue.flatMap(SportsCategory.init(rawValue:)) ?? .other
        iconView.image = UIImage(named: category.iconName) ?? UIImage(named: SportsCategory.other.iconName)
        titleLabel.text = item.title
        timeLabel.text = item.duration
        calorieLabel.text = item.calories
        divider.isHidden = hidesDivider
    }
}

private extension CalendarExerciseCell {
    func setStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func setLayout() {
        [
            iconView,
            titleLabel,
            timeLabel,
            calorieLabel,
            divider
        ].forEach(contentView.addSubview)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(11)
            $0.leading.equalTo(iconView.snp.trailing).offset(14)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(3)
            $0.leading.equalTo(titleLabel)
        }

        calorieLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        divider.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
