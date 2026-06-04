//
//  OnboardingBaseView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then

class OnboardingBaseView: UIView {
    let titleView = TitleView(leftButtonImage: .arrow)
    let progressBar = RoundedProgressView(progressViewStyle: .bar).then {
        $0.progressTintColor = .primary400
        $0.trackTintColor = .gray100
    }
    let nextButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "다음"
    }
    
    let titleLabel = UILabel(config: .title20Semibold)
    let subTitleLabel = UILabel(config: .body14Regular)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let labelStackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 8
        }
        
        addSubview(titleView)
        addSubview(labelStackView)
        addSubview(nextButton)
        
        titleView.addSubview(progressBar)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        progressBar.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(20)
            $0.horizontalEdges.equalToSuperview().inset(48)
        }
        
        labelStackView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RoundedProgressView: UIProgressView {
    override func layoutSubviews() {
        super.layoutSubviews()

        let radius = bounds.height / 2
        layer.cornerRadius = radius
        clipsToBounds = true

        subviews.forEach {
            $0.layer.cornerRadius = radius
            $0.clipsToBounds = true
        }
    }
}
