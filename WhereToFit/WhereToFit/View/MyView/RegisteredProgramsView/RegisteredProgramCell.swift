//
//  RegisteredProgramCell.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/20/26.
//

import SnapKit
import Then
import UIKit

final class RegisteredProgramCell: UICollectionViewCell {
    static let reuseIdentifier = "RegisteredProgramCell"
    var deleteButtonTapped: (() -> Void)?

    private let programImageView = RoundImageView(image: UIImage(resource: .emptyNotification), type: .roundSquare)
    private let nameLabel = UILabel(config: .body16Medium).then {
        $0.numberOfLines = 1
    }
    private let facilityLabel = UILabel(config: .body12Regular, color: .gray500).then {
        $0.numberOfLines = 1
    }
    private let dayLabel = UILabel(config: .body12Regular, color: .gray500).then {
        $0.numberOfLines = 1
    }
    private let timeLabel = UILabel(config: .body12Regular, color: .gray500).then {
        $0.numberOfLines = 1
    }
    private let scheduleStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .leading
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    private let rightUpperLabel = UILabel(config: .body12Regular, color: .gray600).then {
        $0.textAlignment = .right
        $0.numberOfLines = 1
    }
    private let rightDownLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .gray900
        $0.textAlignment = .right
        $0.numberOfLines = 1
    }
    private let divider = UIView().then {
        $0.backgroundColor = .gray100
    }
    private let deleteButton = UIButton(type: .custom).then {
        let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        let image = UIImage(systemName: "minus.circle.fill", withConfiguration: configuration)?
            .withRenderingMode(.alwaysTemplate)
        $0.setImage(image, for: .normal)
        $0.tintColor = .systemRed
        $0.isHidden = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
        setPriority()
        deleteButton.addTarget(self, action: #selector(didTapDeleteButton), for: UIControl.Event.touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        deleteButtonTapped = nil
        deleteButton.isHidden = true
        programImageView.image = UIImage(resource: .emptyNotification)
    }
}

extension RegisteredProgramCell {
    func configure(item: RegisteredProgramsReactor.RegisteredProgramItem, isEditing: Bool) {
        nameLabel.text = item.programName
        facilityLabel.text = item.facilityNameText.map { "\($0) |" }
        facilityLabel.isHidden = item.facilityNameText == nil
        dayLabel.text = item.dayText
        timeLabel.text = item.timeText
        rightUpperLabel.text = ""
        rightDownLabel.text = ""
        rightDownLabel.isHidden = item.reservationMethodText == nil
        deleteButton.isHidden = isEditing == false
        programImageView.image = item.sportsCategory
            .flatMap { UIImage(named: $0.imageName) } ?? UIImage(resource: .noImages)
    }

    @objc func didTapDeleteButton() {
        deleteButtonTapped?()
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
            rightUpperLabel,
            rightDownLabel,
            deleteButton,
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
            $0.trailing.lessThanOrEqualTo(rightUpperLabel.snp.leading).offset(-8)
        }

        scheduleStackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(rightUpperLabel.snp.leading).offset(-8)
        }

        rightUpperLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(7)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(72)
        }

        deleteButton.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.size.equalTo(32)
        }

        rightDownLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(programImageView.snp.bottom).inset(9)
            $0.leading.greaterThanOrEqualTo(nameLabel)
        }

        divider.snp.makeConstraints {
            $0.leading.equalTo(programImageView.snp.trailing).offset(12)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
