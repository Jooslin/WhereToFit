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
class IconButton: UIControl {
    private enum Metric {
        static let hitSize = CGSize(width: 44, height: 44)
    }
    
    enum ButtonState {
        case normal, selected
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

    private let stackView: UIStackView
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let rightIconImageView: UIImageView
    
    private var normalImage: UIImage?
    private var selectedImage: UIImage?
    private var normalRightImage: UIImage?
    private var selectedRightImage: UIImage?
    private let iconSize: CGSize
    private let spacing: CGFloat
    private let iconSize: IconSize
    private var touchSize = Metric.hitSize
    
    // 고유 크기 계산
    override var intrinsicContentSize: CGSize {
        var widths: [CGFloat] = []
        var heights: [CGFloat] = []
        
        if !iconImageView.isHidden {
            widths.append(iconSize.size.width)
            heights.append(iconSize.size.height)
        }
        
        if !titleLabel.isHidden {
            let titleSize = titleLabel.intrinsicContentSize
            widths.append(titleSize.width)
            heights.append(titleSize.height)
        }
        
        if !rightIconImageView.isHidden {
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
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.5 : 1
        }
    }
    
    init(
        image: UIImage? = nil,
        selectedImage: UIImage? = nil,
        title: String? = nil,
        labelConfig: LabelConfiguration = .body14Medium,
        rightImage: UIImage? = nil,
        selectedRightImage: UIImage? = nil,
        iconSize: IconSize = .regular,
        spacing: CGFloat = 4
    ) {
        self.normalImage = image
        self.selectedImage = selectedImage
        self.normalRightImage = rightImage
        self.selectedRightImage = selectedRightImage
        self.iconSize = iconSize
        self.spacing = spacing
        self.iconSize = iconSize
        
        // set attributes
        iconImageView = UIImageView(image: image).then {
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = false
        }
        titleLabel = UILabel(text: title ?? "", config: labelConfig).then {
            $0.textAlignment = .center
            $0.numberOfLines = 1
            $0.isUserInteractionEnabled = false
        }
        rightIconImageView = UIImageView(image: rightImage).then {
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = false
        }
        stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel, rightIconImageView]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = spacing
            $0.isUserInteractionEnabled = false
        }
        
        super.init(frame: .zero)
        
        // set priority
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // set Layout
        iconImageView.isHidden = image == nil
        titleLabel.isHidden = title == nil
        rightIconImageView.isHidden = rightImage == nil
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        [iconImageView, rightIconImageView].forEach {
            $0.snp.makeConstraints {
                $0.width.height.equalTo(iconSize.size)
            }
        }
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
    
    private func updateImage() {
        iconImageView.image = isSelected ? selectedImage ?? normalImage : normalImage
        rightIconImageView.image = isSelected ? selectedRightImage ?? normalRightImage : normalRightImage
    }
    
    private func invalidateLayout() {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        superview?.setNeedsLayout()
    }
}

//MARK: Configure
extension IconButton {
    // 이미지 설정
    func setImage(_ image: UIImage?, rightImage: UIImage? = nil, for state: ButtonState) {
        if let image {
            switch state {
            case .normal:
                normalImage = image
                iconImageView.isHidden = false
            case .selected:
                selectedImage = image
            }
        }
        
        if let rightImage {
            switch state {
            case .normal:
                normalRightImage = rightImage
                rightIconImageView.isHidden = false
            case .selected:
                selectedRightImage = rightImage
            }
        }
        
        updateImage()
        invalidateLayout()
    }
    
    // 타이틀 설정
    func setTitle(_ text: String) {
        titleLabel.text = text
        titleLabel.isHidden = false
        invalidateLayout()
    }
    
    // 색상 설정
    func applyColor(_ color: UIColor) {
        normalImage = normalImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        selectedImage = selectedImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        normalRightImage = normalRightImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        selectedRightImage = selectedRightImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        titleLabel.textColor = color
        updateImage()
    }
    
    // 터치 범위 설정
    func setTouchSize(_ size: CGSize) {
        touchSize = size
    }
}

extension Reactive where Base: IconButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
