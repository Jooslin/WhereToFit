//
//  ProfileManagementViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class ProfileManagementViewController: BaseViewController<ProfileManagementReactor> {
    let profileManagementView = ProfileManagementView()

    override func loadView() {
        view = profileManagementView
    }

    override func bind(reactor: ProfileManagementReactor) {
        profileManagementView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)
    }
}
