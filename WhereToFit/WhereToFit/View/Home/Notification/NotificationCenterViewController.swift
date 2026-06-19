//
//  NotificationCenterViewController.swift
//  WhereToFit
//
//  Created by 김주희 on 6/19/26.
//

import RxCocoa
import RxFlow
import RxRelay
import RxSwift
import UIKit
import UserNotifications

final class NotificationCenterViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()

    private let notificationCenterView = NotificationCenterView()
    private let disposeBag = DisposeBag()
    private let settingsStore = ProgramReminderSettingsStore.shared
    private var latestNotificationStatus = NotificationStatus.allEnabled

    override func loadView() {
        view = notificationCenterView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true

        notificationCenterView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        notificationCenterView.enableNotificationButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.handleEnableNotificationButtonTap()
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotificationStatus),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        refreshNotificationStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
        refreshNotificationStatus()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension NotificationCenterViewController {
    enum NotificationStatus {
        case allEnabled
        case systemDisabled
        case reservationDisabled
        case startDisabled
        case programDisabled

        var warningTitle: String {
            switch self {
            case .allEnabled:
                return ""
            case .systemDisabled:
                return "앱 알림이 꺼져있어요"
            case .reservationDisabled:
                return "프로그램 예약 알림이 꺼져있어요"
            case .startDisabled:
                return "프로그램 시작 알림이 꺼져있어요"
            case .programDisabled:
                return "프로그램 알림이 꺼져있어요"
            }
        }

    }

    @objc func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] notificationSettings in
            guard let self else { return }

            let programSettings = self.settingsStore.load()
            let status = self.notificationStatus(
                authorizationStatus: notificationSettings.authorizationStatus,
                programSettings: programSettings
            )

            DispatchQueue.main.async {
                self.latestNotificationStatus = status
                self.notificationCenterView.updateNotificationWarning(
                    isHidden: status == .allEnabled,
                    title: status.warningTitle
                )
            }
        }
    }

    func notificationStatus(
        authorizationStatus: UNAuthorizationStatus,
        programSettings: ProgramReminderSettings
    ) -> NotificationStatus {
        guard authorizationStatus.isNotificationEnabled else {
            return .systemDisabled
        }

        switch (programSettings.isReservationReminderEnabled, programSettings.isStartReminderEnabled) {
        case (true, true):
            return .allEnabled
        case (false, false):
            return .programDisabled
        case (false, true):
            return .reservationDisabled
        case (true, false):
            return .startDisabled
        }
    }

    func handleEnableNotificationButtonTap() {
        steps.accept(AppStep.notificationSetting)
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
