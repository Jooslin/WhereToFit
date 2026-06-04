//
//  ColoredLabel.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit

/**
 배경색을 가지는 배지 형태의 라벨입니다.

 아래와 같이 사용할 수 있습니다.
 ```swift
 private let matchLabel = ColoredLabel(text: "", style: .fill)
 private let placeLabel = ColoredLabel(text: "", style: .border)
 ```
 
 - Parameters:
   - style: Label에 적용할 스타일
 */

class ColoredLabel: UILabel {
    enum Style {
        case fill
        case border
    }

    private let horizontalPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 2

    init(text: String, style: Style) {
        super.init(frame: .zero)
        self.apply(font: .systemFont(ofSize: 12, weight: .regular), color: .primary500, lines: 1)
        self.apply(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
    }
    
    func apply(style: Style) {
        switch style {
        case .fill:
            backgroundColor = .primary50
            layer.borderWidth = 0
        case .border:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.primary100.cgColor
        }
    }
    
    // 내부 패딩을 위한 override 메서드 - 안쪽으로 인셋을 확보하고 가운데에 글자가 들어갈 수 있도록 해줌
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.drawText(in: rect.inset(by: insets))
    }
    
    // 패딩까지 포함한 레이아웃으로 컨텐트 크기를 잡도록 해주는 override 메서드
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + horizontalPadding * 2,
            height: size.height + verticalPadding * 2
        )
    }
}
