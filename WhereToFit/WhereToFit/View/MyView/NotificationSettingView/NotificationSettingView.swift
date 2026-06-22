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
    let titleView = TitleView(text: "알림 설정", leftButtonImage: UIImage(resource: .arrowLeft))

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

    func update(
        isReservationReminderEnabled: Bool,
        isStartReminderEnabled: Bool,
        startReminderOffsetTitle: String
    ) {
        reservationAlertSwitch.setOn(isReservationReminderEnabled, animated: false)
        startAlertSwitch.setOn(isStartReminderEnabled, animated: false)
        timeSettingRow.update(title: startReminderOffsetTitle, isEnabled: isStartReminderEnabled)
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
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        settingGroup.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(32)
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
        var configuration = UIButton.Configuration.plain()
        configuration.title = "30분 전"
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .primary600
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        configuration.background.strokeColor = .primary400
        configuration.background.backgroundColor = .primary25
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 17
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 13, weight: .medium)
            return attributes
        }

        $0.configuration = configuration
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, isEnabled: Bool) {
        var configuration = timeButton.configuration
        configuration?.title = title
        timeButton.configuration = configuration
        timeButton.isEnabled = isEnabled
        alpha = isEnabled ? 1 : 0.45
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
