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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reactor?.action.onNext(.viewWillAppear)
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

        myView.iCloudSyncInfoButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.openAppSettings()
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.iCloudSyncStatus)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, status in
                owner.myView.updateICloudStatus(isAvailable: status == .available)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.profileSummary)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, summary in
                owner.myView.updateProfileSummary(
                    nickname: summary.nickname,
                    homeAddress: summary.homeAddress
                )
            }
            .disposed(by: disposeBag)
    }
}

private extension MyViewController {
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        UIApplication.shared.open(url)
    }
}
