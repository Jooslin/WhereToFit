//
//  RegisteredProgramsViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class RegisteredProgramsViewController: BaseViewController<RegisteredProgramsReactor> {
    let registeredProgramsView = RegisteredProgramsView()

    override func loadView() {
        view = registeredProgramsView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.viewWillAppear)
    }

    override func bind(reactor: RegisteredProgramsReactor) {
        registeredProgramsView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)
    }
}
