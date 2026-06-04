//
//  OnboardViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import Then

final class OnboardingViewController: BaseViewController<OnboardingReactor> {
    let onboardingView = OnboardingPersonalInfoView()
    override func loadView() {
        view = onboardingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
//    override func bind(reactor: TempReactor) {
//       
//    }
    
}


#Preview {
    OnboardingViewController(reactor: OnboardingReactor())
}
