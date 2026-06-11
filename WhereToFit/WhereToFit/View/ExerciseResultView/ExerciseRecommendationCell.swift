//
//  ExerciseRecommendationCell.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import SnapKit
import Then
import UIKit

final class ExerciseRecommendationCell: UICollectionViewCell {
    static let reuseIdentifier = "ExerciseRecommendationCell"

    private let exerciseImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    private let titleLabel = UILabel(config: .body15)
    private let tagStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 6
    }
    private let relatedProgramLabel = UILabel(text: "관련 프로그램 보기", config: .body12Medium, color: .gray500)
    private let arrowImageView = UIImageView(image: UIImage(resource: .arrowRight)).then {
        $0.tintColor = .gray400
        $0.contentMode = .scaleAspectFit
    }
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

extension ExerciseRecommendationCell {
    func configure(item: ExerciseResultReactor.RecommendationItem, hidesDivider: Bool) {
        titleLabel.text = item.title
        exerciseImageView.image = item.icon.image
        divider.isHidden = hidesDivider

        tagStackView.arrangedSubviews.forEach {
            tagStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        item.tags.forEach {
            tagStackView.addArrangedSubview(ExerciseTagLabel(text: $0))
        }
    }
}

private extension ExerciseResultReactor.RecommendationIcon {
    var image: UIImage {
        switch self {
        case .aquaticSports:
            return UIImage(resource: .aquaticSports)
        }
    }
}

private extension ExerciseRecommendationCell {
    func setStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func setLayout() {
        [
            exerciseImageView,
            titleLabel,
            tagStackView,
            relatedProgramLabel,
            arrowImageView,
            divider
        ].forEach(contentView.addSubview)

        exerciseImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalTo(exerciseImageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(relatedProgramLabel.snp.leading).offset(-8)
        }

        tagStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(relatedProgramLabel.snp.leading).offset(-8)
        }

        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        relatedProgramLabel.snp.makeConstraints {
            $0.trailing.equalTo(arrowImageView.snp.leading).offset(-4)
            $0.centerY.equalToSuperview()
        }

        divider.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}

private final class ExerciseTagLabel: UILabel {
    init(text: String) {
        super.init(frame: .zero)

        self.text = text
        apply(font: .systemFont(ofSize: 12, weight: .medium), color: .primary500, lines: 1)
        textAlignment = .center
        backgroundColor = .primary50
        layer.cornerRadius = 10
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 16, height: 20)
    }
}
