//
//  OnboardingButton.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

class OnboardingButton: DesignButton {
    private let imageView = UIImageView(image: .gym)
    private let subTitleLabel: UILabel = UILabel(config: .body14Regular, color: .gray400, lines: 1).then {
        $0.textAlignment = .left
    }
    private let buttonType: OnboardingButtonType
    
    private lazy var labelStackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel]).then {
        $0.axis = .horizontal
        $0.spacing = 16
        
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private lazy var imageHorizontalStackView = UIStackView(arrangedSubviews: [imageView, titleLabel]).then {
        $0.axis = .horizontal
        $0.spacing = 16
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private lazy var imageVerticalStackView = UIStackView(arrangedSubviews: [imageView, titleLabel]).then {
        $0.axis = .vertical
        $0.spacing = 10
        $0.alignment = .center
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    var subTitle: String? {
        get { subTitleLabel.text }
        set { subTitleLabel.text = newValue }
    }
    
    override var isSelected: Bool {
        didSet {
            if let selectedConfig {
                background.backgroundColor = isSelected ? selectedConfig.color : config.color
                titleLabel.textColor = isSelected ? selectedConfig.titleColor : config.titleColor
                subTitleLabel.textColor = isSelected ? selectedConfig.titleColor : config.titleColor
                background.layer.borderWidth = isSelected ? selectedConfig.style.borderWidth : config.style.borderWidth
                background.layer.borderColor = isSelected ? selectedConfig.borderColor.cgColor : config.borderColor.cgColor
            }
        }
    }
    
    init(config: ButtonConfiguration, selectedConfig: ButtonConfiguration? = nil, type: OnboardingButtonType) {
        self.buttonType = type
        super.init(config: config, selectedConfig: selectedConfig)
        
        titleLabel.removeFromSuperview()
        
        switch buttonType {
        case .subTitle:
            addSubview(labelStackView)
            titleLabel.textAlignment = .left
        case .image:
            addSubview(imageHorizontalStackView)
            titleLabel.textAlignment = .left
        case .card:
            addSubview(imageVerticalStackView)
        case .label:
            addSubview(titleLabel)
            titleLabel.textAlignment = .left
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutContent() {
        switch buttonType {
        case .subTitle:
            labelStackView.frame = bounds.inset(by: config.size.padding)
        case .image:
            imageHorizontalStackView.frame = bounds.inset(by: config.size.padding)
            imageView.frame.size = CGSize(width: 24, height: 24)
        case .card:
            imageVerticalStackView.frame = bounds.inset(by: config.size.padding)
            imageView.frame.size = CGSize(width: 36, height: 36)
        case .label:
           titleLabel.frame = bounds.inset(by: config.size.padding)
        }
    }
}

extension OnboardingButton {
    enum OnboardingButtonType {
        case subTitle
        case image
        case label
        case card
    }
}

extension Reactive where Base: OnboardingButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
