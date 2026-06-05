//
//  HomeTitleView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit

final class HomeTitleView: TitleView {
    init() {
        super.init(
            leftButtonImage: .locationPinFilled,
            rightButtonImage: .alarm,
            leftButton: IconButton(
                title: "지역",
                labelConfig: .title20Semibold,
                rightImage: .arrowDown
            )
        )
        
        leftButton.setContentHuggingPriority(.required, for: .horizontal)
        leftButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        leftButton.snp.remakeConstraints {
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        leftButton.applyColor(.gray900)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
