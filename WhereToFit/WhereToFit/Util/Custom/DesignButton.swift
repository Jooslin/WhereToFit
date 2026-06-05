//
//  Button.swift
//  WhereToFit
//
//  Created by 변예린 on 5/28/26.
//

import UIKit
import Then
import RxSwift
import RxCocoa

/**
 ButtonConfiguration을 통해 디자인 시스템에 기반한 Button을 생성합니다.

 아래와 같이 사용할 수 있습니다.
 ```swift
 let mediumBlueButton = DesignButton(config: .mediumFilledBlue) // 색상 버튼 사용시 + 타이틀 x
 let largeBorderButton = DesignButton(config: .largeBorderBlue).then {
     $0.title = "large border blue"
 } // 테두리 버튼 사용시 + 타이틀 적용
 
 func bind(reactor: TempReactor) {
    largeBorderButton.rx.tap
        .subscribe(onNext: {
            print("largeBorderButtonTapped")
        })
        .disposed(by: disposeBag)
 } // Reactive 확장으로 기존 UIButton처럼 이벤트를 구독할 수 있습니다.
 ```
 
 - Parameters:
   - config: ButtonConfiguration(기존에 정의된 것을 사용하거나 필요 시 생성하여 사용)
*/
class DesignButton: UIControl {
    private let config: ButtonConfiguration
    private let selectedConfig: ButtonConfiguration?
    
    let background: UIView
    let titleLabel: UILabel
    
    var title: String?  {
        get { titleLabel.text }
        set { titleLabel.text = newValue}
    }
    
    override var intrinsicContentSize: CGSize {
        return config.size.size
    }
    
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            background.backgroundColor = isEnabled ? config.color : .gray200
            titleLabel.textColor = isEnabled ? config.titleColor : .white
            isUserInteractionEnabled = isEnabled
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if let selectedConfig {
                background.backgroundColor = isSelected ? selectedConfig.color : config.color
                titleLabel.textColor = isSelected ? selectedConfig.titleColor : config.titleColor
                background.layer.borderWidth = isSelected ? selectedConfig.style.borderWidth : config.style.borderWidth
                background.layer.borderColor = isSelected ? selectedConfig.borderColor.cgColor : config.borderColor.cgColor
            }
        }
    }
    
    init(config: ButtonConfiguration, selectedConfig: ButtonConfiguration? = nil) {
        self.config = config
        self.selectedConfig = selectedConfig
        
        background = switch config.style {
        case .fill:
            ButtonBackgroundView(config: config)
        case .border:
            ButtonBackgroundView(config: config)
        }
        
        titleLabel = UILabel(config: config.size.labelConfig, color: config.titleColor).then {
            $0.textAlignment = .center
        }
        
        super.init(frame: .zero)
        
        addSubview(background)
        addSubview(titleLabel)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        layoutContent()
    }
    
    func layoutContent() {
        titleLabel.frame = bounds.inset(by: config.size.padding)
    }
}

extension DesignButton {
    private class ButtonBackgroundView: UIView {
        init(config: ButtonConfiguration) {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            
            backgroundColor = config.color
            if config.style.borderWidth > 0 {
                layer.borderWidth = config.style.borderWidth
                layer.borderColor = config.titleColor.cgColor
            }
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }
    }
}

extension Reactive where Base: DesignButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
