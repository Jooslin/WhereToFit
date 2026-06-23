//
//  UILabel_.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit

extension UILabel {
    func apply(
        font: UIFont? = nil,
        color: UIColor? = nil,
        lines: Int? = nil
    ) {
//        self.font = UIFontMetrics(forTextStyle: config.textStyle).scaledFont(for: config.font)
//        self.adjustsFontForContentSizeCategory = true
        
        self.font = font ?? self.font
        self.textColor = color ?? self.textColor
        self.numberOfLines = lines ?? self.numberOfLines
    }
    
    convenience init(
        text: String = "",
        config: LabelConfiguration,
        color: UIColor? = nil,
        lines: Int? = nil
    ) {
        self.init()
        self.text = text
        self.font = config.font
        self.textColor = color ?? config.color
        self.numberOfLines = lines ?? config.lines
    }
    
    // 줄 간격 설정
    func setTextWithLineHeight(text: String, height: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = height
        paragraphStyle.maximumLineHeight = height
        
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font as Any,
                .foregroundColor: textColor as Any,
                .paragraphStyle: paragraphStyle
            ])
    }
}
