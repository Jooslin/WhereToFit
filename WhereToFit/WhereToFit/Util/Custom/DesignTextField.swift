//
//  OnboardingTextField.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit

class DesignTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .gray50
        textColor = .gray900
        
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
