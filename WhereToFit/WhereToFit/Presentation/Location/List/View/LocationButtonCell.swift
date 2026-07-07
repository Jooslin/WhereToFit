//
//  LocationButtonCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/16/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class LocationButtonCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    let button = IconButton(config: .largeBorderBlue, style: .leftImage, iconSize: .tiny).then {
        $0.normalImage = .plus
        $0.title = "위치 추가"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        contentView.addSubview(button)
        
        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

//MARK: Reactive
extension Reactive where Base: LocationButtonCell {
    var addButtonTap: ControlEvent<Void> {
        base.button.rx.tap
    }
}
