//
//  OnboardingExperienceView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxSwift

final class OnboardingExperienceView: OnboardingBaseView {
    private(set) var buttons: [OnboardingButton] = []
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .experience) {
        let source = ExerciseExperience.allCases
        buttons = source.reduce([OnboardingButton]()) { arr, experience in
            let button = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .subTitle).then {
                $0.title = experience.rawValue
                $0.subTitle = experience.subTitle
            }
            
            return arr + [button]
        }
        
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingExperienceView {
    private func setLayout() {
        let stackView = UIStackView(arrangedSubviews: buttons).then {
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

//MARK: Reactive
extension Reactive where Base: OnboardingExperienceView {
    var buttonSelected: ControlEvent<String> {
        let events = base.buttons.map { button in
            button.rx.tap.map { button.title ?? "" }
        }
        
        return ControlEvent(events: Observable.merge(events))
    }
}
