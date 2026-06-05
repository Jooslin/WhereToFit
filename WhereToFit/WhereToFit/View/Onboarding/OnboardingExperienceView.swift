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

    }
}
