//
//  NotificationSettingView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import SnapKit
import Then
import UIKit

final class NotificationSettingView: UIView {
    let titleView = TitleView(text: "알림 설정", leftButtonImage: UIImage(systemName: "chevron.left"))

    private let reservationAlertRow = NotificationToggleRow(title: "내 프로그램 예약 알림", isOn: false)
    private let startAlertRow = NotificationToggleRow(title: "내 프로그램 시작 전 알림", isOn: true)
    private let timeSettingRow = NotificationTimeRow()

    var reservationAlertSwitch: UISwitch {
        reservationAlertRow.toggleSwitch
    }

    var startAlertSwitch: UISwitch {
        startAlertRow.toggleSwitch
    }

    var timeSettingButton: UIButton {
        timeSettingRow.timeButton
    }

    private lazy var settingGroup = MenuGroupView(rows: [
        reservationAlertRow,
        startAlertRow,
        timeSettingRow
    ])

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

private extension NotificationSettingView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            settingGroup
        ].forEach(addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(11)
            $0.horizontalEdges.equalToSuperview()
        }

        settingGroup.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(36)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
}

private final class NotificationToggleRow: UIView {
    private let titleLabel: UILabel
    let toggleSwitch = UISwitch().then {
        $0.onTintColor = .primary400
    }

    init(title: String, isOn: Bool) {
        titleLabel = UILabel(text: title, config: .body14Regular)
        super.init(frame: .zero)

        toggleSwitch.isOn = isOn
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NotificationToggleRow {
    func setLayout() {
        addSubview(titleLabel)
        addSubview(toggleSwitch)

        snp.makeConstraints {
            $0.height.equalTo(48)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }

        toggleSwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
    }
}

private final class NotificationTimeRow: UIView {
    private let titleLabel = UILabel(text: "알림 시간 설정", config: .body14Regular)
    private let optionLabel = UILabel(text: "프로그램 시작", config: .body13Medium, color: .gray500)
    let timeButton = UIButton(type: .system).then {
        $0.setTitle("30분 전", for: .normal)
        $0.setTitleColor(.primary600, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.primary400.cgColor
        $0.layer.cornerRadius = 17
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        $0.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        $0.tintColor = .primary600
        $0.semanticContentAttribute = .forceRightToLeft
        $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
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

private extension NotificationTimeRow {
    func setLayout() {
        [
            titleLabel,
            optionLabel,
            timeButton
        ].forEach(addSubview)

        snp.makeConstraints {
            $0.height.equalTo(48)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }

        timeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(34)
        }

        optionLabel.snp.makeConstraints {
            $0.trailing.equalTo(timeButton.snp.leading).offset(-10)
            $0.centerY.equalToSuperview()
        }
    }
}
