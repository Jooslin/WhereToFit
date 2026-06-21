//
//  ProfileManagementViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class ProfileManagementViewController: BaseViewController<ProfileManagementReactor> {
    let profileManagementView = ProfileManagementView()
    private weak var activeInputField: ProfileInputField?

    override func loadView() {
        view = profileManagementView
    }

    override func bind(reactor: ProfileManagementReactor) {
        Observable.just(ProfileManagementReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileManagementView.titleView.rx.leftButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        bindInputSanitizers()
        bindKeyboardAvoidance()

        profileManagementView.nicknameField.textField.rx.text.orEmpty
            .distinctUntilChanged()
            .map(ProfileManagementReactor.Action.updateNickname)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileManagementView.birthDateField.textField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(profileManagementView.birthDateField.textField.rx.text.orEmpty)
            .map(ProfileManagementReactor.Action.updateBirthday)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        Observable.merge([
            profileManagementView.genderField.maleButton.rx.tap.map { UserGender.male },
            profileManagementView.genderField.femaleButton.rx.tap.map { UserGender.female }
        ])
        .map(ProfileManagementReactor.Action.updateGender)
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        profileManagementView.heightField.textField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(profileManagementView.heightField.textField.rx.text.orEmpty)
            .map(ProfileManagementReactor.Action.updateHeight)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileManagementView.weightField.textField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(profileManagementView.weightField.textField.rx.text.orEmpty)
            .map(ProfileManagementReactor.Action.updateWeight)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        profileManagementView.saveButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { ProfileManagementReactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map { state in
                ProfileManagementViewState(
                    nickname: state.nickname,
                    birthday: state.birthdayText,
                    gender: state.gender,
                    height: state.heightText,
                    weight: state.weightText
                )
            }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, state in
                owner.profileManagementView.update(
                    nickname: state.nickname,
                    birthday: state.birthday,
                    gender: state.gender,
                    height: state.height,
                    weight: state.weight
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isSaveButtonEnabled)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, isEnabled in
                owner.profileManagementView.updateSaveButton(isEnabled: isEnabled)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$error)
            .compactMap { $0 }
            .map { AppStep.alert(title: $0.0, message: $0.1) }
            .bind(to: steps)
            .disposed(by: disposeBag)

        reactor.pulse(\.$saveCompleted)
            .filter { $0 }
            .map { _ in AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

private struct ProfileManagementViewState: Equatable {
    let nickname: String
    let birthday: String
    let gender: UserGender
    let height: String
    let weight: String
}

private extension ProfileManagementViewController {
    func bindInputSanitizers() {
        profileManagementView.birthDateField.textField.rx.controlEvent(.editingChanged)
            .withLatestFrom(profileManagementView.birthDateField.textField.rx.text.orEmpty)
            .bind(with: self) { owner, text in
                let sanitizedText = ValidateOnboardingPersonalInfoUseCase.sanitizeBirthdayInput(text)
                guard text != sanitizedText else { return }
                owner.profileManagementView.birthDateField.textField.text = sanitizedText
            }
            .disposed(by: disposeBag)

        profileManagementView.heightField.textField.rx.controlEvent(.editingChanged)
            .withLatestFrom(profileManagementView.heightField.textField.rx.text.orEmpty)
            .bind(with: self) { owner, text in
                let sanitizedText = ValidateOnboardingPersonalInfoUseCase.sanitizeDecimalInput(text)
                guard text != sanitizedText else { return }
                owner.profileManagementView.heightField.textField.text = sanitizedText
            }
            .disposed(by: disposeBag)

        profileManagementView.weightField.textField.rx.controlEvent(.editingChanged)
            .withLatestFrom(profileManagementView.weightField.textField.rx.text.orEmpty)
            .bind(with: self) { owner, text in
                let sanitizedText = ValidateOnboardingPersonalInfoUseCase.sanitizeDecimalInput(text)
                guard text != sanitizedText else { return }
                owner.profileManagementView.weightField.textField.text = sanitizedText
            }
            .disposed(by: disposeBag)
    }

    func bindKeyboardAvoidance() {
        Observable.merge([
            profileManagementView.heightField.textField.rx.controlEvent(.editingDidBegin)
                .map { [profileManagementView] in profileManagementView.heightField },
            profileManagementView.weightField.textField.rx.controlEvent(.editingDidBegin)
                .map { [profileManagementView] in profileManagementView.weightField }
        ])
        .bind(with: self) { owner, field in
            owner.activeInputField = field
            owner.profileManagementView.scrollToVisible(field)
        }
        .disposed(by: disposeBag)

        Observable.merge([
            profileManagementView.heightField.textField.rx.controlEvent(.editingDidEnd).map { ProfileInputField?.none },
            profileManagementView.weightField.textField.rx.controlEvent(.editingDidEnd).map { ProfileInputField?.none }
        ])
        .bind(with: self) { owner, _ in
            owner.activeInputField = nil
        }
        .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind(with: self) { owner, notification in
                owner.updateKeyboardInset(notification: notification)
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .bind(with: self) { owner, _ in
                owner.profileManagementView.updateKeyboardBottomInset(0)
            }
            .disposed(by: disposeBag)
    }

    func updateKeyboardInset(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardOverlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        profileManagementView.updateKeyboardBottomInset(keyboardOverlap)

        guard let activeInputField else { return }
        profileManagementView.scrollToVisible(activeInputField)
    }
}
