//
//  OnboardViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import Then

final class OnboardingViewController: BaseViewController<OnboardingReactor> {
    let onboardingView = OnboardingBaseView().then {
        $0.progressBar.setProgress(0.5, animated: true)
        $0.nextButton.isEnabled = false
    }
    
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
