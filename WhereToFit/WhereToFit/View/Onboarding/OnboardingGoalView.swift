//
//  OnboardingGoalView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class OnboardingGoalView: OnboardingBaseView {
    private(set) var buttons: [OnboardingButton] = []

    override init(frame: CGRect = .zero, step: OnboardingStep = .goal) {
        let source = ExerciseGoal.allCases
        buttons = source.reduce([OnboardingButton]()) { arr, goal in
            let button = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .image).then {
                $0.title = goal.rawValue
                $0.image = UIImage(named: goal.imageString)
            }
            return arr + [button]
        }
        
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingGoalView {
    private func setLayout() {
        let stackView = UIStackView(
            arrangedSubviews: buttons
        ).then {
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
extension Reactive where Base: OnboardingGoalView {
    var buttonSelected: ControlEvent<String> {
        let events = base.buttons.map { button in
            button.rx.tap.map { button.title ?? "" }
        }
        
        return ControlEvent(events: Observable.merge(events))
    }
}
