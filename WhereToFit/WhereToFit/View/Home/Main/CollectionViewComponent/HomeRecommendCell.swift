//
//  HomeRecommendCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/3/26.
//

import UIKit
import SnapKit
import Then

final class HomeRecommendCell: UICollectionViewCell {
    private let imageView = RoundImageView(image: nil, type: .circle)
    private let label = UILabel(config: .body16Medium).then {
        $0.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 이미지 초기화
        imageView.image = nil
    }
}

//MARK: Configure
extension HomeRecommendCell {
    func configure(_ category: SportsCategory) {
        imageView.image = UIImage(named: category.imageName)
        label.text = category.rawValue
    }
}

//MARK: Layout
extension HomeRecommendCell {
    private func setLayout() {
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        
        imageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.width.height.equalTo(100)
        }
        
        label.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
