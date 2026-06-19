//
//  OnboardingEndView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/19/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingEndView: UIView {
    private let imageView = UIImageView(image: .roundcheck)
    private let resultLabel = UILabel(text: "검사 정보가 저장되었습니다!", config: .title20Semibold).then {
            $0.textAlignment = .center
        }
    private let descriptionLabel = UILabel(
        text: """
        앞으로 검사 결과를 반영한 운동을
        AI가 추천해드릴게요.
        """,
        config: .body14Regular,
        color: .gray400
    ).then {
            $0.textAlignment = .center
        }
    
    let homeButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "나에게 맞는 운동 보러가기"
    }
    let retryButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "검사 다시하기"
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let labelStack = UIStackView(arrangedSubviews: [resultLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 8
        }
        
        let logoStackView = UIStackView(arrangedSubviews: [imageView, labelStack]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 32
        }
        
        let buttonStackView = UIStackView(arrangedSubviews: [homeButton, retryButton]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 12
        }
        
        addSubview(logoStackView)
        addSubview(buttonStackView)
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(64)
        }
        
        logoStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(0.95)
        }
        
        buttonStackView.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
