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
    private let historyStore = NotificationHistoryStore.shared
    private var latestNotificationStatus = NotificationStatus.allEnabled
    private var historyItems: [NotificationHistoryItem] = []

    override func loadView() {
        view = notificationCenterView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
        setupCollectionView()

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
            selector: #selector(refreshNotificationCenterState),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        refreshNotificationCenterState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
        refreshNotificationCenterState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension NotificationCenterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        historyItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NotificationHistoryCell.reuseIdentifier,
            for: indexPath
        ) as? NotificationHistoryCell else {
            return UICollectionViewCell()
        }

        let item = historyItems[indexPath.item]
        cell.configure(
            item: item,
            elapsedTimeText: elapsedTimeText(from: item.receivedAt)
        )
        return cell
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

    func setupCollectionView() {
        notificationCenterView.collectionView.register(
            NotificationHistoryCell.self,
            forCellWithReuseIdentifier: NotificationHistoryCell.reuseIdentifier
        )
        notificationCenterView.collectionView.dataSource = self

        notificationCenterView.collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.notificationCenterView.collectionView.deselectItem(at: indexPath, animated: true)
                guard owner.historyItems.indices.contains(indexPath.item),
                      owner.historyItems[indexPath.item].isProgramNotification else {
                    return
                }

                owner.steps.accept(AppStep.registeredPrograms)
            }
            .disposed(by: disposeBag)
    }

    @objc func refreshNotificationCenterState() {
        refreshNotificationStatus()
        refreshNotificationHistory()
    }

    func refreshNotificationStatus() {
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

    func refreshNotificationHistory() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self else { return }

            self.historyStore.merge(notifications: notifications)
            let items = self.historyStore.load()

            DispatchQueue.main.async {
                self.historyItems = items
                self.notificationCenterView.updateNotificationHistory(isEmpty: items.isEmpty)
                self.notificationCenterView.collectionView.reloadData()
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

    func elapsedTimeText(from date: Date) -> String {
        let elapsedSeconds = max(0, Int(Date().timeIntervalSince(date)))

        switch elapsedSeconds {
        case 0..<60:
            return "방금 전"
        case 60..<3600:
            return "\(elapsedSeconds / 60)분 전"
        case 3600..<86400:
            return "\(elapsedSeconds / 3600)시간 전"
        default:
            return "\(elapsedSeconds / 86400)일 전"
        }
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
