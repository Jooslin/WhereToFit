//
//  OnboardViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxRelay
import RxSwift
import ReactorKit

final class OnboardingViewController: BaseViewController<OnboardingReactor> {
    private let containerView = UIView()
    private var currentStepView: UIView?
    private var stepViewDisposeBag = DisposeBag()
    
    private let selectedAddressRelay = PublishRelay<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setLayout()
    }
    
    override func bind(reactor: OnboardingReactor) {
        reactor.state
            .map(\.currentStep)
            .distinctUntilChanged()
            .bind(with: self) { owner, step in
                owner.render(step: step)
            }
            .disposed(by: disposeBag)
    }
}

private extension OnboardingViewController {
    func setLayout() {
        view.backgroundColor = .white
        view.addSubview(containerView)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func render(step: OnboardingStep) {
        stepViewDisposeBag = DisposeBag()
        currentStepView?.removeFromSuperview()
        
        let nextView = makeStepView(for: step)
        containerView.addSubview(nextView)
        
        nextView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        bindStepView(nextView)
        currentStepView = nextView
    }
    
    func makeStepView(for step: OnboardingStep) -> UIView {
        switch step {
        case .start:
            return OnboardingStartView()
        case .personalInfo:
            return OnboardingPersonalInfoView()
        case .experience:
            return OnboardingExperienceView()
        case .goal:
            return OnboardingGoalView()
        case .preference:
            return OnboardingCardButtonsView(step: .preference)
        case .disabled:
            return OnboardingCardButtonsView(step: .disabled)
        case .facility:
            return OnboardingFacilityView()
        case .end:
            return OnboardingEndView()
        }
    }
    
    func bindStepView(_ stepView: UIView) {
        guard let reactor else {
            return
        }
        
        if let startView = stepView as? OnboardingStartView {
            startView.startButton.rx.tap
                .map { OnboardingReactor.Action.nextButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            startView.skipButton.rx.tap
                .bind(with: self) { owner, _ in
                    owner.steps.accept(AppStep.main)
                }
                .disposed(by: stepViewDisposeBag)
        }
        
        if let personalInfoView = stepView as? OnboardingPersonalInfoView {
            personalInfoView.rx.nicknameTextFieldEditingDidEnd
                .map {
                    OnboardingReactor.Action.updateNickname($0)
                }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.rx.birthdayTextFieldEditingDidEnd
                .map { OnboardingReactor.Action.updateBirthday($0) }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.rx.genderButtonTap
                .map {
                    OnboardingReactor.Action.updateGender($0)
                }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.residenceTextField.rx.tap
                .withUnretained(self)
                .subscribe(onNext: { `self`, _ in
                    self.presentPostCodeSelection()
                })
                .disposed(by: stepViewDisposeBag)
            
            selectedAddressRelay
                .map {
                    OnboardingReactor.Action.updateAddress($0)
                }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.rx.weightTextFieldEditingDidEnd
                .map {
                    OnboardingReactor.Action.updateWeight($0)
                }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.rx.heightTextFieldEditingDidEnd
                .map {
                    OnboardingReactor.Action.updateHeight($0)
                }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            personalInfoView.nextButton.rx.tap
                .map { OnboardingReactor.Action.nextButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
        }
        
        if let baseView = stepView as? OnboardingBaseView {
            baseView.nextButton.rx.tap
                .map { OnboardingReactor.Action.nextButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            baseView.titleView.rx.leftButtonTap
                .map { OnboardingReactor.Action.backButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
        }
        
        if let endView = stepView as? OnboardingEndView {
            endView.homeButton.rx.tap
                .bind(with: self) { owner, _ in
                    owner.steps.accept(AppStep.main)
                }
                .disposed(by: stepViewDisposeBag)
            
            endView.retryButton.rx.tap
                .map { OnboardingReactor.Action.retryButtonTapped }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
        }
    }
}

extension OnboardingViewController {
    private func presentPostCodeSelection() {
        let vc = KakaoPostCodeViewController()
        vc.onSelectAddress = { [weak self] address in
            self?.selectedAddressRelay.accept(address)
        }
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: false)
    }
    
    @objc private func didTapBackground() {
        currentStepView?.endEditing(true)
    }
}

#Preview {
    OnboardingViewController(reactor: OnboardingReactor(dateService: DateService()))
}
