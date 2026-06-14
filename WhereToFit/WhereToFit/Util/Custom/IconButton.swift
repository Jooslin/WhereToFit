//
//  IconButton.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

/**
 아이콘 이미지가 포함된 배경색 투명의 단일 Button을 생성합니다. 최소 터치영역은 44x44 point입니다.

 아래와 같이 사용할 수 있습니다.
 ```swift
 let favoriteButton = IconButton(image: nil, selectedImage: .heartFilled)
 favoriteButton.setImage(image: .heart, for: .normal) // normal 상태의 이미지 설정
 favoriteButton.applyColor(UIColor.black) // 이미지 색상 설정
 ```
 
 파라미터들을 통해 우측 이미지, label 또한 생성할 수 있습니다. Configure 부분의 메서드들을 통해 이미지, 타이틀, 색상, 터치 범위를 수정할 수 있습니다.
 
 - Parameters:      
   - image: 기본 상태에서 보여줄 좌측 이미지
    - selectedImage: 선택 상태(`isSelected == true`)에서 보여줄 좌측 이미지
    - title: 버튼 타이틀
    - labelConfig: 버튼 타이틀에 적용할 LabelConfiguration
    - rightImage: 기본 상태에서 보여줄 우측 이미지
    - rightSelectedImage: 선택 상태(`isSelected == true`)에서 보여줄 우측 이미지
    - spacing: 좌측 / 레이블 / 우측 각 요소간 간격
*/
class IconButton: DesignButton {
    private let style: ButtonStyle
    private let spacing: CGFloat
    private let iconSize: IconSize
    private var touchSize = Metric.hitSize
    
    private var normalTintColorOverride: UIColor?
    private var selectedTintColorOverride: UIColor?
    
    private lazy var stackView =  UIStackView(arrangedSubviews: [leftImageView, titleLabel, rightImageView]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = spacing
        $0.isUserInteractionEnabled = false
    }
    private let leftImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }
    private let rightImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }
    
    // 이미지
    var normalImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    var normalRightImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    var selectedImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    var selectedRightImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    // 고유 크기 계산
    override var intrinsicContentSize: CGSize {
        if case .icon = style {
            return iconSize.size
        }
        
        var widths: [CGFloat] = []
        var heights: [CGFloat] = []
        
        if !leftImageView.isHidden {
            widths.append(iconSize.size.width)
            heights.append(iconSize.size.height)
        }
        
        if !titleLabel.isHidden {
            let titleSize = titleLabel.intrinsicContentSize
            widths.append(titleSize.width)
            heights.append(titleSize.height)
        }
        
        if !rightImageView.isHidden {
            widths.append(iconSize.size.width)
            heights.append(iconSize.size.height)
        }
        
        guard !widths.isEmpty else { return .zero }
        
        let totalSpacing = spacing * CGFloat(max(0, widths.count - 1))
        return CGSize(
            width: widths.reduce(0, +) + totalSpacing,
            height: heights.max() ?? 0
        )
    }
    
    // isSelected되면 이미지 변경
    override var isSelected: Bool {
        didSet {
            updateImage()
 
            let normalColor = normalTintColorOverride ?? config.titleColor
            let selectedColor = selectedTintColorOverride ?? selectedConfig?.titleColor ?? config.titleColor
            
            leftImageView.tintColor = isSelected ? selectedColor : normalColor
            rightImageView.tintColor = isSelected ? selectedColor : normalColor
            titleLabel.textColor = isSelected ? selectedColor : normalColor
        }
    }
    
    init(
        config: ButtonConfiguration = .icon,
        selectedConfig: ButtonConfiguration? = nil,
        style: ButtonStyle = .icon,
        iconSize: IconSize = .regular,
        spacing: CGFloat = 4
    ) {
        self.iconSize = iconSize
        self.spacing = spacing
        self.style = style
        
        super.init(config: config, selectedConfig: selectedConfig)
        
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 터치 범위 설정
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - touchSize.width) / 2
        let heightInset = min(0, bounds.height - touchSize.height) / 2
        let hitFrame = bounds.insetBy(dx: widthInset, dy: heightInset)
        return hitFrame.contains(point)
    }
    
    override func layoutContent() {
        stackView.frame = bounds.inset(by: config.size.padding)
    }
}

//MARK: Layout
extension IconButton {
    private func setLayout() {
        // set isHidden
        switch style {
        case .icon:
            titleLabel.isHidden = true
            rightImageView.isHidden = true
        case .leftImage:
            rightImageView.isHidden = true
        case .rightImage:
            leftImageView.isHidden = true
        case .bothImage:
            break
        }
        
        // set priority
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // set layout
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        [leftImageView, rightImageView].forEach {
            $0.snp.makeConstraints {
                $0.width.height.equalTo(iconSize.size)
            }
        }
    }
}

//MARK: Configure
extension IconButton {    
    // 색상 설정
    func applyColor(color: UIColor, selectedColor: UIColor? = nil) {
        normalTintColorOverride = color
        selectedTintColorOverride = selectedColor
        
        titleLabel.textColor = isSelected ? selectedColor : color
        updateImage()
    }
    
    // 터치 범위 설정
    func setTouchSize(_ size: CGSize) {
        touchSize = size
    }
    
    // 이미지 업데이트
    private func updateImage() {
        leftImageView.image = isSelected ? selectedImage ?? normalImage : normalImage
        rightImageView.image = isSelected ? selectedRightImage ?? normalRightImage : normalRightImage
        
        let normalColor = normalTintColorOverride ?? config.titleColor
        let selectedColor = selectedTintColorOverride ?? selectedConfig?.titleColor ?? config.titleColor
        
        leftImageView.tintColor = isSelected ? selectedColor : normalColor
        rightImageView.tintColor = isSelected ? selectedColor : normalColor
    }
}

//MARK: Components
extension IconButton {
    private enum Metric {
        static let hitSize = CGSize(width: 44, height: 44)
    }
    
    enum IconSize {
        case compact
        case regular

        var size: CGSize {
            switch self {
            case .compact:
                return CGSize(width: 20, height: 20)
            case .regular:
                return CGSize(width: 24, height: 24)
            }
        }
    }
    
    enum ButtonStyle {
        case icon
        case leftImage
        case rightImage
        case bothImage
    }
}

//MARK: Reactive
extension Reactive where Base: IconButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
