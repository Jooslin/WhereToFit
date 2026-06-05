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
        $0.setPlaceholder(text: "닉네임을 입력해주세요")
    }
    let birthdayTextField = DesignTextField().then {
        $0.setPlaceholder(text: "ex)19991208")
    }
    let maleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "남성"
        $0.isSelected = true
    }
    let femaleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "여성"
    }
    let residenceTextField = DesignTextField().then {
        $0.setPlaceholder(text: "주소 찾기")
    }
    let heightTextField = DesignTextField().then {
        $0.setPlaceholder(text: "키를 입력해주세요")
    }
    let weightTextField = DesignTextField().then {
        $0.setPlaceholder(text: "몸무게를 입력해주세요")
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        titleLabel.text = "안녕하세요!"
        subTitleLabel.text = "운동 추천을 위해 몇 가지 정보를 알려주세요."
        
        progressBar.setProgress(0.125, animated: true)
        
        setLayout()
    }
}

extension OnboardingPersonalInfoView {
    private func setLayout() {
        let buttonStackView = UIStackView(arrangedSubviews: [maleButton, femaleButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
        }
        
        let nicknameStackView = makeStackView(title: "닉네임", view: nicknameTextField)
        let birthdayStackView = makeStackView(title: "생년월일", view: birthdayTextField)
        let genderStackView = makeStackView(title: "성별", view: buttonStackView)
        let residenceStackView = makeStackView(title: "거주 지역 (선택)", view: residenceTextField)
        
        let heightStackView = makeStackView(title: "키 (선택)", view: heightTextField)
        let weightStackView = makeStackView(title: "몸무게 (선택)", view: weightTextField)
        let bodyStackView = UIStackView(arrangedSubviews: [heightStackView, weightStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 23
            $0.distribution = .fill
        }
        
        let stackView = UIStackView(arrangedSubviews: [nicknameStackView, birthdayStackView, genderStackView, residenceStackView, bodyStackView]).then {
            $0.axis = .vertical
            $0.spacing = 20
            $0.alignment = .leading
            $0.distribution = .fill
        }
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }
        
        birthdayTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }
        
        residenceTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }
        
        bodyStackView.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }
        
        heightTextField.snp.makeConstraints {
            $0.width.equalTo(heightStackView.snp.width)
        }
        
        weightTextField.snp.makeConstraints {
            $0.width.equalTo(weightStackView.snp.width)
        }
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
