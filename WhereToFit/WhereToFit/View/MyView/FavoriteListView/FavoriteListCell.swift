//
//  FavoriteListCell.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//
import UIKit
import Then
import SnapKit

final class FavoriteListCell: UICollectionViewCell {
    static let reuseIdentifier = "FavoriteProgramCell"
    var favoriteButtonTapped: (() -> Void)?

    private let programImageView = ProgramImageView(image: nil)
    private let nameLabel = UILabel(config: .body16Medium).then {
        $0.numberOfLines = 1
    }
    private let facilityLabel = UILabel(config: .body12Regular, color: .gray500)
    private let dayLabel = UILabel(config: .body12Regular, color: .gray500)
    private let timeLabel = UILabel(config: .body12Regular, color: .gray500)
    private let scheduleStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .leading
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let distanceLabel = UILabel(config: .body12Regular, color: .gray600).then {
        $0.textAlignment = .right
    }
    private let reservationBadge = FavoriteReservationBadge()
    private let priceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .gray900
        $0.textAlignment = .right
    }
    private let divider = UIView().then {
        $0.backgroundColor = .gray100
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
        setPriority()
        programImageView.favoriteButton.addTarget(self, action: #selector(didTapFavoriteButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        favoriteButtonTapped = nil
        programImageView.favoriteButton.isSelected = true
    }
}

private final class FavoriteReservationBadge: UIView {
    private let iconView = UIImageView(image: .date).then {
        $0.tintColor = .gray600
        $0.contentMode = .scaleAspectFit
    }
    private let titleLabel = UILabel(text: "예약필요", config: .body12Regular)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension FavoriteReservationBadge {
    func setLayout() {
        backgroundColor = .gray50
        layer.cornerRadius = 4

        [
            iconView,
            titleLabel
        ].forEach(addSubview)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(5)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(3)
            $0.trailing.equalToSuperview().inset(6)
            $0.verticalEdges.equalToSuperview().inset(3)
        }
    }
}

extension FavoriteListCell {
    func configure(item: FavoriteListReactor.FavoriteItem) {
        nameLabel.text = item.name
        facilityLabel.text = item.facilityLabelText
        facilityLabel.isHidden = item.facilityLabelText == nil
        dayLabel.text = item.day
        timeLabel.text = item.time
        distanceLabel.text = item.distance
        priceLabel.text = item.price
        programImageView.favoriteButton.isSelected = true
    }

    @objc func didTapFavoriteButton() {
        favoriteButtonTapped?()
    }

    func setPriority() {
        [
            facilityLabel,
            dayLabel,
            timeLabel
        ].forEach {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    func setLayout() {
        [
            programImageView,
            nameLabel,
            scheduleStackView,
            distanceLabel,
            reservationBadge,
            priceLabel,
            divider
        ].forEach(contentView.addSubview)

        [
            facilityLabel,
            dayLabel,
            timeLabel
        ].forEach(scheduleStackView.addArrangedSubview)

        programImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.size.equalTo(82)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalTo(programImageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(distanceLabel.snp.leading).offset(-8)
        }

        scheduleStackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(distanceLabel.snp.leading).offset(-8)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(7)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(72)
        }

        reservationBadge.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.bottom.equalTo(programImageView.snp.bottom).inset(9)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(reservationBadge)
            $0.leading.greaterThanOrEqualTo(reservationBadge.snp.trailing).offset(8)
        }

        divider.snp.makeConstraints {
            $0.leading.equalTo(programImageView.snp.trailing).offset(12)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
