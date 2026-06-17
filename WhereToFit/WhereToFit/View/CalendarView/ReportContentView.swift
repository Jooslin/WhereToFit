//
//  ReportContentView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/16/26.
//

import SnapKit
import Then
import UIKit

final class ReportContentView: UIView {
    let inputButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "정보 입력하러 가기"
    }

    private let emptyImageView = UIImageView().then {
        $0.image = UIImage(resource: .report)
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel(
        text: "캘린더에서 정보를 입력하면\n리포트를 작성해드려요",
        config: .body16Medium,
        color: .gray600,
        lines: 2
    ).then {
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReportContentView {
    func setLayout() {
        [
            emptyImageView,
            messageLabel,
            inputButton
        ].forEach(addSubview)

        emptyImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(118)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(220)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        inputButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.bottom.lessThanOrEqualToSuperview().inset(24)
        }
    }
}
