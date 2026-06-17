//
//  FacilityDetailView.swift
//  WhereToFit
//
//  Created by 김주희 on 6/8/26.
//

import UIKit
import SnapKit
import Then

enum DetailKind {
    case program
    case facility

    var heroHeightRatio: CGFloat {
        switch self {
        case .program: return 0.87
        case .facility: return 1.0
        }
    }
}

final class FacilityDetailView: UIView {
    let heroGradientLayer = CAGradientLayer()

    let scrollView = UIScrollView().then {
        $0.contentInsetAdjustmentBehavior = .never
        $0.showsVerticalScrollIndicator = false
    }

    let contentView = UIView()

    let heroImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .gray100
    }

    let pageIndicator = UIPageControl().then {
        $0.numberOfPages = 6
        $0.currentPage = 0
        $0.currentPageIndicatorTintColor = .white
        $0.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        $0.isUserInteractionEnabled = false
        $0.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)
    }

    let backButton = UIButton(type: .system)
    let favoriteButton = UIButton(type: .system)

    let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 30
    }

    let facilityNameButton = UIButton(type: .system).then {
        $0.contentHorizontalAlignment = .left
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    let phoneInfoButton = UIButton(type: .system).then {
        $0.contentHorizontalAlignment = .left
        $0.titleLabel?.numberOfLines = 1
    }

    let reservationButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "예약하기"
    }

    private let kind: DetailKind
    private let showsReservationButton: Bool

    init(kind: DetailKind, showsReservationButton: Bool) {
        self.kind = kind
        self.showsReservationButton = showsReservationButton
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        heroGradientLayer.frame = heroImageView.bounds
        [backButton, favoriteButton].forEach {
            $0.layer.cornerRadius = $0.bounds.height / 2
        }
    }

    private func configureLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(heroImageView)
        contentView.addSubview(pageIndicator)
        contentView.addSubview(contentStackView)
        addSubview(backButton)
        addSubview(favoriteButton)

        if showsReservationButton {
            addSubview(reservationButton)
        }

        heroImageView.layer.addSublayer(heroGradientLayer)

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            if showsReservationButton {
                $0.bottom.equalTo(reservationButton.snp.top).offset(-12)
            } else {
                $0.bottom.equalTo(safeAreaLayoutGuide)
            }
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        heroImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(snp.width).multipliedBy(kind.heroHeightRatio)
        }

        pageIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(heroImageView.snp.bottom).inset(10)
            $0.height.equalTo(16)
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalTo(heroImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(showsReservationButton ? 20 : 34)
        }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(14)
            $0.leading.equalToSuperview().inset(16)
            $0.size.equalTo(34)
        }

        favoriteButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(14)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(34)
        }

        if showsReservationButton {
            reservationButton.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.bottom.equalTo(safeAreaLayoutGuide).inset(16)
                $0.height.equalTo(48)
            }
        }
    }
}
