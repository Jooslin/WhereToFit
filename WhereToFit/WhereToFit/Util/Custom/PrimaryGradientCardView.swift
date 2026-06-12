//
//  PrimaryGradientCardView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import UIKit

final class PrimaryGradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
    }
}

private extension PrimaryGradientCardView {
    func setStyle() {
        layer.cornerRadius = 12
        clipsToBounds = true

        gradientLayer.colors = [
            UIColor.primary25.cgColor,
            UIColor.gray50.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        layer.insertSublayer(gradientLayer, at: 0)
    }
}
