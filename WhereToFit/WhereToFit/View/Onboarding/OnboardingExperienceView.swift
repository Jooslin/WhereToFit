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
    let subTitleButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
        $0.title = "초급"
        $0.subTitle = "초급임"
        $0.isSelected = true
    }
    let imageButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
        $0.title = "종목"
    }
    let titleButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .label).then  {
        $0.title = "title"
    }
    
    let cardButton = OnboardingButton(config: .onboardingCard, selectedConfig: .selectedOnboardingCard, type: .card).then {
        $0.title = "card"
        $0.isSelected = true
        
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
