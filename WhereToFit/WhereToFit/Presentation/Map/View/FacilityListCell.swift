//
//  FacilityListCell.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import UIKit
import Kingfisher
import SnapKit
import Then

/// 지도 하단 모달에서 시설 셀과 프로그램 셀을 함께 표현하는 재사용 셀입니다.
/// 다른 화면에서 같은 UI가 필요하면 `FacilityProgramListItemViewModel`을 만들어 `configure(with:)`로 주입하면 됩니다.
final class FacilityListCell: UITableViewCell {
    static let reuseIdentifier = "FacilityListCell"

    private let thumbnailView = RoundImageView(image: nil, type: .roundSquare).then {
        $0.backgroundColor = .systemGray5
    }

    private let matchingLabel = ColoredLabel(text: "", style: .fill)

    private let distanceLabel = UILabel(text: "", config: .body12Regular, color: .gray600).then {
        $0.textAlignment = .right
    }

    private let titleLabel = UILabel(text: "", config: .body16Medium, color: .gray900).then {
        $0.numberOfLines = 1
    }

    private let detailLabel = UILabel(text: "", config: .body12Regular, color: .gray600).then {
        $0.numberOfLines = 1
    }

    private let reservationBadgeView = UIView().then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 6
        $0.layer.masksToBounds = true
    }

    private let reservationIconView = UIImageView().then {
        $0.image = UIImage(named: "date")?.withTintColor(.gray600, renderingMode: .alwaysOriginal)
        $0.contentMode = .scaleAspectFit
    }

    private let reservationLabel = UILabel(text: "예약필요", config: .body12Medium, color: .gray600)

    private let priceLabel = UILabel(text: "", config: .body16Medium, color: .gray900).then {
        $0.textAlignment = .right
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.kf.cancelDownloadTask()
        thumbnailView.image = nil
    }

    func configure(with facility: FitnessFacility) {
        configure(with: FacilityProgramListItemViewModel(facility: facility))
    }

    /// 셀 UI는 ViewModel만 바라보게 두어, API 모델이 바뀌어도 셀 레이아웃 재사용이 쉽도록 합니다.
    func configure(with viewModel: FacilityProgramListItemViewModel) {
        matchingLabel.text = viewModel.badgeText
        distanceLabel.text = viewModel.distanceText
        titleLabel.text = viewModel.title
        detailLabel.text = viewModel.detailText
        reservationBadgeView.isHidden = viewModel.showsReservationBadge == false
        priceLabel.text = viewModel.priceText
        thumbnailView.backgroundColor = viewModel.thumbnailBackgroundColor

        let placeholderImage = UIImage(named: viewModel.placeholderImageName) ?? UIImage(named: "homeBackground")
        if let imageURL = viewModel.imageURL {
            thumbnailView.kf.setImage(with: imageURL, placeholder: placeholderImage)
        } else {
            thumbnailView.image = placeholderImage
        }
    }

    private func configureLayout() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(thumbnailView)
        contentView.addSubview(matchingLabel)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(reservationBadgeView)
        reservationBadgeView.addSubview(reservationIconView)
        reservationBadgeView.addSubview(reservationLabel)
        contentView.addSubview(priceLabel)

        thumbnailView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(102)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(18)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.greaterThanOrEqualTo(64)
        }

        matchingLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(thumbnailView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(distanceLabel.snp.leading).offset(-8)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(matchingLabel.snp.bottom).offset(4)
            $0.leading.equalTo(matchingLabel)
            $0.trailing.equalToSuperview().inset(16)
        }

        detailLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(matchingLabel)
            $0.trailing.equalToSuperview().inset(16)
        }

        reservationBadgeView.snp.makeConstraints {
            $0.top.equalTo(detailLabel.snp.bottom).offset(12)
            $0.leading.equalTo(matchingLabel)
            $0.height.equalTo(28)
        }

        reservationIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        reservationLabel.snp.makeConstraints {
            $0.leading.equalTo(reservationIconView.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(reservationBadgeView)
            $0.leading.greaterThanOrEqualTo(reservationBadgeView.snp.trailing).offset(12)
        }
    }
}

/// 팀원이 모달의 "시설/프로그램 리스트 셀" 의도를 더 쉽게 알 수 있도록 남겨둔 별칭입니다.
typealias FacilityProgramListCell = FacilityListCell
