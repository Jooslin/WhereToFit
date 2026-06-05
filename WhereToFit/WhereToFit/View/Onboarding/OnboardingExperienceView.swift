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
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        titleLabel.text = "운동 경험을 알려주세요!"
        subTitleLabel.text = "스스로 생각하는 정도를 선택해주세요."
        
        progressBar.setProgress(0.125, animated: true)
        
        setLayout()
    }
}

extension OnboardingExperienceView {
    private func setLayout() {
        addSubview(subTitleButton)
        addSubview(imageButton)
        addSubview(titleButton)
        addSubview(cardButton)
        
        subTitleButton.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        imageButton.snp.makeConstraints {
            $0.top.equalTo(subTitleButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        titleButton.snp.makeConstraints {
            $0.top.equalTo(imageButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        cardButton.snp.makeConstraints {
            $0.top.equalTo(titleButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
    }
}
