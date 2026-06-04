//
//  IconButton.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import Then
import RxSwift
import RxCocoa

class IconButton: UIControl {
    private enum Metric {
        static let hitSize = CGSize(width: 44, height: 44)
        static let iconSize = CGSize(width: 24, height: 24)
    }
    
    enum ButtonState {
        case normal, selected
    }
    
    private let iconImageView: UIImageView
    private var normalImage: UIImage?
    private var selectedImage: UIImage?
    
    var image: UIImage?  {
        get { iconImageView.image }
        set { iconImageView.image = newValue }
    }
    
    override var intrinsicContentSize: CGSize {
        return Metric.iconSize
    }
    
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
    
    init(image: UIImage? = nil, selectedImage: UIImage? = nil) {
        self.normalImage = image
        self.selectedImage = selectedImage
        iconImageView = UIImageView(image: image).then {
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = false
        }
        
        super.init(frame: .zero)
        
        addSubview(iconImageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.frame = CGRect(
            x: (bounds.width - Metric.iconSize.width) / 2,
            y: (bounds.height - Metric.iconSize.height) / 2,
            width: Metric.iconSize.width,
            height: Metric.iconSize.height
        )
    }
    
    // 터치 범위 설정
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - Metric.hitSize.width) / 2
        let heightInset = min(0, bounds.height - Metric.hitSize.height) / 2
        let hitFrame = bounds.insetBy(dx: widthInset, dy: heightInset)
        return hitFrame.contains(point)
    }
    
    private func updateImage() {
        guard let selectedImage else {
            iconImageView.image = normalImage
            return
        }
        
        iconImageView.image = isSelected ? selectedImage : normalImage
    }
}

extension IconButton {
    // 이미지 설정
    func setImage(_ image: UIImage?, for state: ButtonState) {
        if let image {
            switch state {
            case .normal:
                normalImage = image
            case .selected:
                selectedImage = image
            }
        }
        updateImage()
    }
    
    // 색상 설정
    func applyColor(_ color: UIColor) {
        normalImage = normalImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        selectedImage = selectedImage?.withTintColor(color, renderingMode: .alwaysOriginal)
        updateImage()
    }
}

extension Reactive where Base: IconButton {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
