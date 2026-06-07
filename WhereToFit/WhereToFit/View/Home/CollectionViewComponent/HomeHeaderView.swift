//
//  HomeHeaderView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/31/26.
//

import UIKit
import SnapKit

final class HomeHeaderView: UICollectionReusableView {
    let titleLabel = UILabel(config: .title18)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
