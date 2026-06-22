//
//  NotificationSettingViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit
import UserNotifications

final class NotificationSettingViewController: BaseViewController<NotificationSettingReactor> {
    let notificationSettingView = NotificationSettingView()

    override func loadView() {
        view = notificationSettingView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let reactor else { return }
        forceReminderTogglesOffIfSystemNotificationDisabled(reactor: reactor)
    }

    override func bind(reactor: NotificationSettingReactor) {
        notificationSettingView.titleView.rx.leftButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        notificationSettingView.reservationAlertSwitch.rx.isOn
            .skip(1)
            .bind(with: self) { owner, isOn in
                owner.handleReminderToggleChange(
                    isOn: isOn,
                    toggleSwitch: owner.notificationSettingView.reservationAlertSwitch,
                    reactor: reactor,
                    actionBuilder: NotificationSettingReactor.Action.setReservationReminderEnabled
                )
            }
            .disposed(by: disposeBag)

        notificationSettingView.startAlertSwitch.rx.isOn
            .skip(1)
            .bind(with: self) { owner, isOn in
                owner.handleReminderToggleChange(
                    isOn: isOn,
                    toggleSwitch: owner.notificationSettingView.startAlertSwitch,
                    reactor: reactor,
                    actionBuilder: NotificationSettingReactor.Action.setStartReminderEnabled
                )
            }
            .disposed(by: disposeBag)

        notificationSettingView.timeSettingButton.rx.tap
            .withLatestFrom(reactor.state.map(\.offsetOptions))
            .bind(with: self) { owner, options in
                owner.presentOffsetActionSheet(
                    options: options,
                    reactor: reactor
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, state in
                owner.notificationSettingView.update(
                    isReservationReminderEnabled: state.isReservationReminderEnabled,
                    isStartReminderEnabled: state.isStartReminderEnabled,
                    startReminderOffsetTitle: state.selectedOffset.title
                )
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .bind(with: self) { owner, _ in
                guard let reactor = owner.reactor else { return }
                owner.forceReminderTogglesOffIfSystemNotificationDisabled(reactor: reactor)
            }
            .disposed(by: disposeBag)
    }
}

private extension NotificationSettingViewController {
    func forceReminderTogglesOffIfSystemNotificationDisabled(reactor: NotificationSettingReactor) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus.isNotificationEnabled == false else {
                return
            }

            DispatchQueue.main.async {
                reactor.action.onNext(.setReservationReminderEnabled(false))
                reactor.action.onNext(.setStartReminderEnabled(false))
            }
        }
    }

    func handleReminderToggleChange(
        isOn: Bool,
        toggleSwitch: UISwitch,
        reactor: NotificationSettingReactor,
        actionBuilder: @escaping (Bool) -> NotificationSettingReactor.Action
    ) {
        guard isOn else {
            reactor.action.onNext(actionBuilder(false))
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self, weak toggleSwitch] settings in
            DispatchQueue.main.async {
                guard let self else { return }

                guard settings.authorizationStatus.isNotificationEnabled else {
                    toggleSwitch?.setOn(false, animated: true)
                    self.openNotificationSettings()
                    return
                }

                reactor.action.onNext(actionBuilder(true))
            }
        }
    }

    func openNotificationSettings() {
        guard let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }

    func presentOffsetActionSheet(
        options: [ProgramReminderOffset],
        reactor: NotificationSettingReactor
    ) {
        let alertController = UIAlertController(
            title: "알림 시간 설정",
            message: nil,
            preferredStyle: .actionSheet
        )

        options.forEach { offset in
            let action = UIAlertAction(title: offset.title, style: .default) { _ in
                reactor.action.onNext(.selectStartReminderOffset(offset))
            }

            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        alertController.popoverPresentationController?.sourceView = notificationSettingView.timeSettingButton
        alertController.popoverPresentationController?.sourceRect = notificationSettingView.timeSettingButton.bounds

        present(alertController, animated: true)
    }
}

private extension UNAuthorizationStatus {
    var isNotificationEnabled: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
}
