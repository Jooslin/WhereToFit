//
//  OnboardingExperienceView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingExperienceView: OnboardingBaseView {
    let starterButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
        $0.title = "초급"
        $0.subTitle = "이제 시작하는 단계예요"
    }
    
    let beginnerButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
        $0.title = "입문"
        $0.subTitle = "가볍게 경험해봤어요"
    }
    
    let intermediateButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
        $0.title = "중급"
        $0.subTitle = "꾸준히 운동하고 있어요"
    }
    
    let advancedButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
        $0.title = "숙련"
        $0.subTitle = "어느 운동이든 잘 해내요"
    }
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .experience) {
        super.init(frame: frame, step: step)        
        setLayout()
    }
}

extension OnboardingExperienceView {
    private func setLayout() {
        let stackView = UIStackView(arrangedSubviews: [starterButton, beginnerButton, intermediateButton, advancedButton]).then {
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
