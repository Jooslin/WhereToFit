//
//  OnboardingButton.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import Then
import RxSwift
import RxCocoa

class OnboardingButton: DesignButton {
    private let imageView = UIImageView()
    private let subTitleLabel: UILabel = UILabel(config: .body14Regular)

    var subTitle: String? {
        get { subTitleLabel.text }
        set { subTitleLabel.text = newValue }
    }
    
    init(config: ButtonConfiguration, selectedConfig: ButtonConfiguration? = nil, type: OnboardingButtonType) {
        super.init(config: config, selectedConfig: selectedConfig)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OnboardingButton {
    
}

extension OnboardingButton {
    enum OnboardingButtonType {
        case subTitle
        case image
        case label
    }
}

extension Reactive where Base: OnboardingButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
