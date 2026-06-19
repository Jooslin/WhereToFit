//
//  OnboardingPReferenceView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class OnboardingCardButtonsView: OnboardingBaseView {
    private(set) var buttons: [OnboardingButton] = []
    
    override init(frame: CGRect = .zero, step: OnboardingStep) {
        let source: [String] = switch step {
        case .preference:
            SportsCategory.allCases.map { $0.rawValue }
        case .disabled:
            DiscomfortBodyPart.allCases.map { $0.rawValue }
        default:
            []
        }
        
        buttons = source.reduce([OnboardingButton]()) { arr, title in
            let button = OnboardingButton(config: .onboardingCard, selectedConfig: .selectedOnboardingCard, type: .card).then {
                $0.title = title
            }
            return arr + [button]
        }
        
        super.init(frame: .zero, step: step)
        setLayout()
    }
}

extension OnboardingCardButtonsView {
    private func setLayout() {
        let stackView = makeButtonStack()
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    private func makeButtonStack() -> UIStackView {
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

//MARK: Reactive
extension Reactive where Base: OnboardingCardButtonsView {
    var buttonSelected: ControlEvent<String> {
        let events = base.buttons.map { button in
            button.rx.tap.map { button.title ?? "" }
        }
        
        return ControlEvent(events: Observable.merge(events))
    }
}
