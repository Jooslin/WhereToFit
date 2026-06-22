//
//  OnboardingStartView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingStartView: UIView {
    private enum Layout {
        static let logoSize = CGSize(width: 138, height: 98)
        static let logoTopOffset = 196
        static let descriptionTopOffset = 24
    }
    
    private let imageView = UIImageView(image: .appLogo)
    private let descriptionLabel = UILabel(
        text: """
        간단한 운동 테스트로
        나에게 맞는 맞춤형 운동 경험을 시작해보세요
        """,
        config: .body14Medium).then {
            $0.textAlignment = .center
        }
    
    let startButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "검사 시작하기"
    }
    let skipButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "검사 없이 바로 시작할래요"
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let buttonStackView = UIStackView(arrangedSubviews: [startButton, skipButton]).then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.spacing = 12
        }
        
        addSubview(imageView)
        addSubview(descriptionLabel)
        addSubview(buttonStackView)
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(Layout.logoTopOffset)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(Layout.logoSize)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(Layout.descriptionTopOffset)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.lessThanOrEqualToSuperview().inset(16)
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
