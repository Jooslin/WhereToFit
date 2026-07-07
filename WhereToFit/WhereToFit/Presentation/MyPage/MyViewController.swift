//
//  MyViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/2/26.
//

import ReactorKit
import RxCocoa
import RxSwift
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
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.profileManagement)
            }
            .disposed(by: disposeBag)

        myView.registeredProgramsAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.registeredPrograms)
            }
            .disposed(by: disposeBag)

        myView.notificationSettingAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.notificationSetting)
            }
            .disposed(by: disposeBag)

        myView.favoriteProgramsAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.favoritePrograms)
            }
            .disposed(by: disposeBag)

        myView.exerciseResultAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.exerciseResult)
            }
            .disposed(by: disposeBag)

        myView.iCloudSyncInfoButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openAppSettings()
            }
            .disposed(by: disposeBag)

        myView.privacyPolicyAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openPrivacyPolicy()
            }
            .disposed(by: disposeBag)

        myView.termsOfServiceAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openTermsOfService()
            }
            .disposed(by: disposeBag)

        myView.locationTermsAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openLocationTerms()
            }
            .disposed(by: disposeBag)

        myView.openSourceLicenseAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openOpenSourceLicense()
            }
            .disposed(by: disposeBag)

        myView.inquiryAccessoryButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.openInquiryMail()
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

    func openPrivacyPolicy() {
        openURL("https://leaflog.notion.site/WhereToFit-3874589f9d0f808087f8d5c0d1343eb8?source=copy_link")
    }

    func openTermsOfService() {
        openURL("https://leaflog.notion.site/WhereToFit-3874589f9d0f80e4b532fa1071613f15?source=copy_link")
    }

    func openLocationTerms() {
        openURL("https://leaflog.notion.site/WhereToFit-3874589f9d0f80e4b532fa1071613f15?pvs=143")
    }

    func openOpenSourceLicense() {
        openURL("https://leaflog.notion.site/WhereToFit-3874589f9d0f802ab105db88227ff13c?source=copy_link")
    }

    func openInquiryMail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "leaflogapp@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "WhereToFit 문의")
        ]

        guard let url = components.url else { return }

        UIApplication.shared.open(url, options: [:]) { [weak self] isOpened in
            guard isOpened == false else { return }

            self?.steps.accept(
                AppStep.alert(
                    title: "메일 앱을 열 수 없어요",
                    message: "기본 메일 앱 설정을 확인하거나 leaflogapp@gmail.com으로 문의해주세요."
                )
            )
        }
    }

    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }
}
