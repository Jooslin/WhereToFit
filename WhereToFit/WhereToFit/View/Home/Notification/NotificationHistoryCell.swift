//
//  NotificationHistoryCell.swift
//  WhereToFit
//
//  Created by Codex on 6/21/26.
//

import SnapKit
import Then
import UIKit

final class NotificationHistoryCell: UICollectionViewCell {
    static let reuseIdentifier = "NotificationHistoryCell"

    private let typeTitleLabel = UILabel(config: .body12Medium, color: .primary500)
    private let elapsedTimeLabel = UILabel(config: .body12Regular, color: .gray400).then {
        $0.textAlignment = .right
    }
    private let messageLabel = UILabel(config: .body14Medium, color: .gray900, lines: 2)
    private let detailLabel = UILabel(text: "자세히 보기", config: .body12Regular, color: .gray400)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        typeTitleLabel.text = nil
        elapsedTimeLabel.text = nil
        messageLabel.text = nil
    }

    func configure(item: NotificationHistoryItem, elapsedTimeText: String) {
        typeTitleLabel.text = item.typeTitle
        elapsedTimeLabel.text = elapsedTimeText
        messageLabel.text = item.message
    }
}

private extension NotificationHistoryCell {
    func setStyle() {
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
    }

    func setLayout() {
        [
            typeTitleLabel,
            elapsedTimeLabel,
            messageLabel,
            detailLabel
        ].forEach(contentView.addSubview)

        typeTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualTo(elapsedTimeLabel.snp.leading).offset(-12)
        }

        elapsedTimeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(20)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(typeTitleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        detailLabel.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }
    }
}
