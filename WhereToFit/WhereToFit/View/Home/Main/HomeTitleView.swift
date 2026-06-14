//
//  HomeTitleView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then

final class HomeTitleView: TitleView {
    init() {
        let leftButton = IconButton(config: .locationIcon, style: .bothImage).then {
            $0.normalImage = .locationPinFilled
            $0.title = "지역"
            $0.normalRightImage = .arrowDown
        }
        
        super.init(
            leftButtonImage: .locationPinFilled,
            rightButtonImage: .alarm,
            leftButton: leftButton
        )
        
        leftButton.setContentHuggingPriority(.required, for: .horizontal)
        leftButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        leftButton.snp.remakeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
