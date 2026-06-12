//
//  MyViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/2/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class MyViewController: BaseViewController<MyReactor> {
    let myView = MyView()

    override func loadView() {
        view = myView
    }

    override func bind(reactor: MyReactor) {
        myView.profileButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.profileManagement)
            }
            .disposed(by: disposeBag)

        myView.registeredProgramsAccessoryButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.registeredPrograms)
            }
            .disposed(by: disposeBag)

        myView.notificationSettingAccessoryButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.notificationSetting)
            }
            .disposed(by: disposeBag)

        myView.favoriteProgramsAccessoryButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.favoritePrograms)
            }
            .disposed(by: disposeBag)

        myView.exerciseResultAccessoryButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.exerciseResult)
            }
            .disposed(by: disposeBag)
    }
}
