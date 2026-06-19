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

final class NotificationCenterViewController: UIViewController, Stepper {
    let steps = PublishRelay<Step>()

    private let notificationCenterView = NotificationCenterView()
    private let disposeBag = DisposeBag()

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
    }
}
