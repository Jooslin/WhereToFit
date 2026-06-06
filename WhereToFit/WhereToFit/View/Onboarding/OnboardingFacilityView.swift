//
//  OnboardingFacilityView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingFacilityView: OnboardingBaseView {
    let negativeButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .label).then {
        $0.title = "아니요, 이제 이용해보려고 합니다"
        $0.isSelected = true
    }
    
    let positiveButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .label).then {
        $0.title = "네, 이용중입니다"
    }
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .facilityExperience) {
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingFacilityView {
    private func setLayout() {
        let stackView = UIStackView(arrangedSubviews: [negativeButton, positiveButton]).then {
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
