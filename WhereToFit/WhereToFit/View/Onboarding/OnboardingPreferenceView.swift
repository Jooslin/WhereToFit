//
//  OnboardingPReferenceView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingPreferenceView: OnboardingBaseView {
    let categories = [
        "헬스", "피트니스", "요가/필라",
        "체조", "댄스/무용", "수중",
        "구기", "빙상", "무도/격투",
        "러닝/사이클", "생활체육", "특수체육"
    ]
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .goal) {
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingPreferenceView {
    private func setLayout() {
        let stackView = makeButtonStack()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func makeButtonStack() -> UIStackView {
        let buttons = categories.reduce([OnboardingButton]()) { arr, title in
            let button = OnboardingButton(config: .onboardingCard, selectedConfig: .selectedOnboardingCard, type: .card).then {
                $0.title = title
            }
            return arr + [button]
        }
        
        let horizontalStacks = stride(from: 0, to: buttons.count, by: 3).map { startIndex in
            let endIndex = min(startIndex + 3, buttons.count)
            var rowViews: [UIView] = Array(buttons[startIndex..<endIndex])
            
            while rowViews.count < 3 {
                rowViews.append(UIView())
            }
            
            return UIStackView(arrangedSubviews: rowViews).then {
                $0.axis = .horizontal
                $0.spacing = 20
                $0.distribution = .fillEqually
            }
        }
        
        return UIStackView(arrangedSubviews: horizontalStacks).then {
            $0.axis = .vertical
            $0.spacing = 8
        }
    }
}
