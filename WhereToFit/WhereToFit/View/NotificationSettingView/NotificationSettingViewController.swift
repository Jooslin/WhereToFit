//
//  NotificationSettingViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class NotificationSettingViewController: BaseViewController<NotificationSettingReactor> {
    let notificationSettingView = NotificationSettingView()

    override func loadView() {
        view = notificationSettingView
    }

    override func bind(reactor: NotificationSettingReactor) {
        notificationSettingView.backButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)
    }
}
