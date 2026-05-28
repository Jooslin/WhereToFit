//
//  Button.swift
//  WhereToFit
//
//  Created by 변예린 on 5/28/26.
//

import UIKit
import Then

class Button: UIControl {
    private let background: UIView
    private let titleLabel: UILabel
    private let padding: UIEdgeInsets
    
    var title: String?  {
        get { titleLabel.text }
        set { titleLabel.text = newValue}
    }
    
    init(config: ButtonConfiguration) {
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
