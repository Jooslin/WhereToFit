//
//  OnboardingProgramAddCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/7/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingProgramAddCell: UICollectionViewCell {
    let imageView = UIImageView(image: .plus)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = bounds.height / 2
    }
}
