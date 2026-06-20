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
        
        if let baseView = stepView as? OnboardingBaseView {
            bindBaseView(baseView, reactor: reactor)
        }
        
        switch stepView {
        case let startView as OnboardingStartView:
            bindStartView(startView, reactor: reactor)
            
        case let personalInfoView as OnboardingPersonalInfoView:
            bindPersonalInfoView(personalInfoView, reactor: reactor)
            
        case let experienceView as OnboardingExperienceView:
            bindExperienceView(experienceView, reactor: reactor)
            
        case let goalView as OnboardingGoalView:
            bindGoalView(goalView, reactor: reactor)
            
        case let cardButtonsView as OnboardingCardButtonsView:
            bindCardButtonsView(cardButtonsView, reactor: reactor)
            
        case let facilityView as OnboardingFacilityView:
            bindFacilityView(facilityView, reactor: reactor)
            
        case let endView as OnboardingEndView:
            bindEndView(endView, reactor: reactor)
            
        default:
            break
        }
    }
    
    func bindStartView(_ startView: OnboardingStartView, reactor: OnboardingReactor) {
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
    
    func bindBaseView(_ baseView: OnboardingBaseView, reactor: OnboardingReactor) {
        baseView.nextButton.rx.tap
            .map { OnboardingReactor.Action.nextButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
        
        baseView.titleView.rx.leftButtonTap
            .map { OnboardingReactor.Action.backButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
    }
    
    func bindPersonalInfoView(_ personalInfoView: OnboardingPersonalInfoView, reactor: OnboardingReactor) {
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
    }
    
    func bindExperienceView(_ experienceView: OnboardingExperienceView, reactor: OnboardingReactor) {
        experienceView.rx.buttonSelected
            .map { OnboardingReactor.Action.updateExerciseExperience($0) }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
        
        reactor.state
            .map(\.exerciseExperience)
            .distinctUntilChanged()
            .bind(with: experienceView) { view, experience in
                view.buttons.forEach {
                    $0.isSelected = $0.title == experience?.rawValue
                }
            }
            .disposed(by: stepViewDisposeBag)
    }
    
    func bindGoalView(_ goalView: OnboardingGoalView, reactor: OnboardingReactor) {
        goalView.rx.buttonSelected
            .map { OnboardingReactor.Action.updateExerciseGoal($0) }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
        
        reactor.state
            .map(\.exerciseGoal)
            .distinctUntilChanged()
            .bind(with: goalView) { view, goal in
                view.buttons.forEach {
                    $0.isSelected = $0.title == goal?.rawValue
                }
            }
            .disposed(by: stepViewDisposeBag)
    }
    
    func bindCardButtonsView(_ cardButtonsView: OnboardingCardButtonsView, reactor: OnboardingReactor) {
        switch cardButtonsView.step {
        case .preference?:
            cardButtonsView.rx.buttonSelected
                .map { OnboardingReactor.Action.togglePreferredSportsCategory($0) }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            reactor.state
                .map(\.preferredSportsCategoryRawValues)
                .distinctUntilChanged()
                .bind(with: cardButtonsView) { view, selectedValues in
                    view.buttons.forEach {
                        $0.isSelected = selectedValues.contains($0.title ?? "")
                    }
                }
                .disposed(by: stepViewDisposeBag)
            
        case .disabled?:
            cardButtonsView.rx.buttonSelected
                .map { OnboardingReactor.Action.toggleDiscomfortBodyPart($0) }
                .bind(to: reactor.action)
                .disposed(by: stepViewDisposeBag)
            
            reactor.state
                .map(\.discomfortBodyParts)
                .distinctUntilChanged()
                .bind(with: cardButtonsView) { view, bodyParts in
                    let selectedValues = bodyParts.map(\.rawValue)
                    view.buttons.forEach {
                        $0.isSelected = selectedValues.contains($0.title ?? "")
                    }
                }
                .disposed(by: stepViewDisposeBag)
            
        default:
            break
        }
    }
    
    func bindFacilityView(_ facilityView: OnboardingFacilityView, reactor: OnboardingReactor) {
        facilityView.rx.negativeButtonTap
            .map { OnboardingReactor.Action.updateUsesPublicFacility(false) }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
        
        facilityView.rx.positiveButtonTap
            .map { OnboardingReactor.Action.updateUsesPublicFacility(true) }
            .bind(to: reactor.action)
            .disposed(by: stepViewDisposeBag)
        
        reactor.state
            .map(\.usesPublicFacility)
            .distinctUntilChanged()
            .bind(with: facilityView) { view, usesPublicFacility in
                view.negativeButton.isSelected = usesPublicFacility == false
                view.positiveButton.isSelected = usesPublicFacility
            }
            .disposed(by: stepViewDisposeBag)
    }
    
    func bindEndView(_ endView: OnboardingEndView, reactor: OnboardingReactor) {
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
