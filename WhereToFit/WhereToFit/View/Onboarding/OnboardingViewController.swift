//
//  OnboardViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import Then
import RxSwift
import ReactorKit

final class OnboardingViewController: BaseViewController<OnboardingReactor> {
    let onboardingView = OnboardingPersonalInfoView()
    override func loadView() {
        view = onboardingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingView.maleButton.addAction(UIAction(handler: { [weak self] _ in
            self?.onboardingView.maleButton.isSelected.toggle()
        }), for: .touchUpInside)
    }
    
    func bind(reactor: TempReactor) {
    }
    
}


#Preview {
    OnboardingViewController(reactor: OnboardingReactor())
}
