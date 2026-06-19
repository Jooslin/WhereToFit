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
}

private extension NotificationCenterView {
    func setStyle() {
        backgroundColor = .systemBackground
    }

    func setLayout() {
        [
            titleView,
            emptyImageView,
            emptyLabel
        ].forEach(addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
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
}
