//
//  NotificationCenterView.swift
//  WhereToFit
//
//  Created by 김주희 on 6/19/26.
//

import SnapKit
import Then
import UIKit

final class NotificationCenterView: UIView {
    let titleView = TitleView(text: "알림", leftButtonImage: UIImage(resource: .arrowLeft))

    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: NotificationCenterView.makeCollectionViewLayout()
    ).then {
        $0.backgroundColor = .systemBackground
        $0.showsVerticalScrollIndicator = false
        $0.isHidden = true
    }

    let enableNotificationButton = UIButton(type: .system).then {
        $0.setTitle("알림 켜기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = LabelConfiguration.body12Medium.font
        $0.backgroundColor = .primary400
        $0.layer.cornerRadius = 19
        $0.clipsToBounds = true
        $0.contentHorizontalAlignment = .center
        $0.contentVerticalAlignment = .center
    }

    private let notificationWarningView = UIView().then {
        $0.backgroundColor = .primary25
        $0.layer.cornerRadius = 12
    }

    private let warningTitleLabel = UILabel(
        text: "알람이 꺼져있어요",
        config: .body14Regular,
        color: .gray400
    )

    private let warningDescriptionLabel = UILabel(
        text: "원하는 알림만 보내드려요",
        config: .body16Medium,
        color: .gray900
    )

    private let emptyImageView = UIImageView(image: .emptyNotification).then {
        $0.contentMode = .scaleAspectFit
    }

    private let emptyLabel = UILabel(text: "도착한 알림이 없어요", config: .body16Medium, color: .gray600).then {
        $0.textAlignment = .center
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

    func updateNotificationWarning(isHidden: Bool, title: String) {
        notificationWarningView.isHidden = isHidden
        warningTitleLabel.text = title
        updateCollectionViewTop(isWarningHidden: isHidden)
    }

    func updateNotificationHistory(isEmpty: Bool) {
        collectionView.isHidden = isEmpty
        emptyImageView.isHidden = isEmpty == false
        emptyLabel.isHidden = isEmpty == false
    }
}

private extension NotificationCenterView {
    static func makeCollectionViewLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(122)
            )
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(122)
            ),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0

        return UICollectionViewCompositionalLayout(section: section)
    }

    func setStyle() {
        backgroundColor = .systemBackground
    }

    func setLayout() {
        [
            titleView,
            notificationWarningView,
            collectionView,
            emptyImageView,
            emptyLabel
        ].forEach(addSubview)

        [
            warningTitleLabel,
            warningDescriptionLabel,
            enableNotificationButton
        ].forEach(notificationWarningView.addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        notificationWarningView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(86)
        }

        updateCollectionViewTop(isWarningHidden: notificationWarningView.isHidden)

        warningTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(enableNotificationButton.snp.leading).offset(-12)
        }

        warningDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(warningTitleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(warningTitleLabel)
            $0.trailing.lessThanOrEqualTo(enableNotificationButton.snp.leading).offset(-12)
        }

        enableNotificationButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(96)
            $0.height.equalTo(38)
        }

        emptyImageView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(180)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(220)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(28)
            $0.centerX.equalToSuperview()
        }
    }

    func updateCollectionViewTop(isWarningHidden: Bool) {
        collectionView.snp.remakeConstraints {
            if isWarningHidden {
                $0.top.equalTo(titleView.snp.bottom).offset(16)
            } else {
                $0.top.equalTo(notificationWarningView.snp.bottom).offset(16)
            }
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}
