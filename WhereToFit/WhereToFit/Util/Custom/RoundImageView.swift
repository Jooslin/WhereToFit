//
//  RoundImageView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit

/**
 둥근 모서리를 가지는 ImageView를 생성합니다.

 아래와 같이 사용할 수 있습니다.
 ```swift
 let circleImageView = RoundImageView(image: .cameraImg, type: .circle) // 원형 ImageView 생성 시
 let roundSquareImageView = RoundImageView(image: .cameraImg, type: .round) // 둥근 사각형 ImageView 생성 시
 ```
 
 - Parameters:
   - image: 표시할 이미지
   - type: 모서리 타입 (원형은 circle, 둥근 사각형은 roundSquare 사용)

*/
 class RoundImageView: UIImageView {
    private let type: RadiusType
    
    init(image: UIImage?, type: RadiusType) {
        self.type = type
        super.init(image: image)
        
        contentMode = .scaleAspectFill
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch type {
        case .circle:
            layer.cornerRadius = frame.width / 2
        case .roundSquare:
            layer.cornerRadius = 12
        }
        
        clipsToBounds = true
    }
}

extension RoundImageView {
    enum RadiusType {
        case circle
        case roundSquare
    }
}
