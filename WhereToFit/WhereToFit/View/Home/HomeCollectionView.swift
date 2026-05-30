//
//  HomeCollectionView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit

final class HomeCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        contentInset = .init(top: 0, left: 0, bottom: 50, right: 0)
        showsVerticalScrollIndicator = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeCollectionView {
    nonisolated
    enum Section: Int {
        case weather = 0
    }
    
    nonisolated
    enum Item: Hashable {
        case weather
    }
}
