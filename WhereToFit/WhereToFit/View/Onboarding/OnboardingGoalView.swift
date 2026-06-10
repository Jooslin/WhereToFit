//
//  OnboardingGoalView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingGoalView: OnboardingBaseView {
    let muscularButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "근력 향상"
    }
    
    let dietButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "다이어트"
    }
    
    let staminaButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "체력 향상"
    }
    
    let postureButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "자세 교정"
    }
    
    let healthCareButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "건강 관리"
    }
    
    let manageStressButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "스트레스 해소"
    }
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .goal) {
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingGoalView {
    private func setLayout() {
        let stackView = UIStackView(
            arrangedSubviews: [muscularButton, dietButton, staminaButton, postureButton, healthCareButton, manageStressButton]
        ).then {
            $0.axis = .vertical
            $0.spacing = 16
            $0.alignment = .center
        }
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
}
