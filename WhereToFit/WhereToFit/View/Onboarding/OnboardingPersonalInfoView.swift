//
//  OnboardingPersonalInfoView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingPersonalInfoView: OnboardingBaseView {
    let nicknameTextField = DesignTextField().then {
        $0.placeholder = "닉네임을 입력해주세요"
    }
    let birthdayTextField = DesignTextField().then {
        $0.placeholder = "ex)19991208"
    }
    let maleButton = DesignButton(config: .smallFilledGray).then {
        $0.title = "남성"
    }
    let femaleButton = DesignButton(config: .smallFilledGray).then {
        $0.title = "여성"
    }
    let residenceTextField = DesignTextField().then {
        $0.placeholder = "주소 찾기"
    }
    let heightTextField = DesignTextField().then {
        $0.placeholder = "키를 입력해주세요"
    }
    let weightTextField = DesignTextField().then {
        $0.placeholder = "몸무게를 입력해주세요"
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        titleLabel.text = "안녕하세요!"
        subTitleLabel.text = "운동 추천을 위해 몇 가지 정보를 알려주세요."
        
        progressBar.setProgress(0.125, animated: true)
    }
}

extension OnboardingPersonalInfoView {
    private func setLayout() {

    }
    
    private func makeStackView(title: String, view: UIView) -> UIStackView {
        let titleLabel = UILabel(text: title, config: .body14Medium)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, view]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 6
        }
        
        return stackView
    }
}
