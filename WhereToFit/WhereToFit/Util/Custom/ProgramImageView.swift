//
//  ProgramImageView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then

final class ProgramImageView: RoundImageView {
    let favoriteButton = IconButton(image: .heart, selectedImage: .heartFilled)
    private let gradientLayer = CAGradientLayer()
    
    init(image: UIImage?) {
        super.init(image: image, type: .roundSquare)
        
        isUserInteractionEnabled = true
        
        let colors: [CGColor] = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        layer.addSublayer(gradientLayer)
        
        addSubview(favoriteButton)
        
        favoriteButton.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.bottom.trailing.equalToSuperview().inset(8)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
