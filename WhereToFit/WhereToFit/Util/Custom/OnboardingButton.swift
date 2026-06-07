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
        $0.isUserInteractionEnabled = false
        
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private lazy var imageHorizontalStackView = UIStackView(arrangedSubviews: [imageView, titleLabel]).then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.alignment = .center
        $0.isUserInteractionEnabled = false
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private lazy var imageVerticalStackView = UIStackView(arrangedSubviews: [imageView, titleLabel]).then {
        $0.axis = .vertical
        $0.spacing = 10
        $0.alignment = .center
        $0.isUserInteractionEnabled = false
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    var subTitle: String? {
        get { subTitleLabel.text }
        set { subTitleLabel.text = newValue }
    }
    
    override var backgroundCornerRadius: CGFloat {
        buttonType == .card ? 16 : super.backgroundCornerRadius
    }
    
    override var isSelected: Bool {
        didSet {
            if let selectedConfig {
                subTitleLabel.textColor = isSelected ? selectedConfig.titleColor : config.titleColor
            }
        }
    }
    
    init(config: ButtonConfiguration, selectedConfig: ButtonConfiguration? = nil, type: OnboardingButtonType) {
        self.buttonType = type
        super.init(config: config, selectedConfig: selectedConfig)
        
        titleLabel.removeFromSuperview()
        
        switch buttonType {
        case .subTitle:
            labelStackView.frame = fallbackContentFrame
            addSubview(labelStackView)
            titleLabel.textAlignment = .left
            
        case .image:
            imageHorizontalStackView.frame = fallbackContentFrame
            addSubview(imageHorizontalStackView)
            titleLabel.textAlignment = .left
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(24)
            }
            
        case .card:
            imageVerticalStackView.frame = fallbackContentFrame
            addSubview(imageVerticalStackView)
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(36)
            }
            
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
        case .card:
            imageVerticalStackView.frame = bounds.inset(by: config.size.padding)
            
        case .label:
            titleLabel.frame = bounds.inset(by: config.size.padding)
        }
    }
    
    // 임시 프레임 사이즈
    private var fallbackContentFrame: CGRect {
        CGRect(origin: .zero, size: config.size.size).inset(by: config.size.padding)
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
