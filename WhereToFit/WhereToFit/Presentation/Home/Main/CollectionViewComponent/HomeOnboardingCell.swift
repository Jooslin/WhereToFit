//
//  HomeOnboardingCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/3/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class HomeOnboardingCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    fileprivate let surveyButton = IconButton(config: .icon, style: .rightImage, spacing: 0).then {
        $0.normalRightImage = .arrowRight
        $0.title = "검사하기"
        $0.titleLabel.apply(font: .systemFont(ofSize: 13, weight: .medium))
        $0.applyColor(color: .primary400)
        $0.setTouchSize(CGSize(width: 90, height: 55))
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.backgroundColor = .primary25
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        
        setLayout()
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

//MARK: Layout
extension HomeOnboardingCell {
    private func setLayout() {
        let imageView = UIImageView(image: .gym)
        let titleLabel = UILabel(text: "나에게 맞는 운동 찾기", config: .body16Medium)
        let subLabel = UILabel(text: "무료 검사를 받아보세요!", config: .body13Regular, color: .gray500)
             
        let titleStackView = UIStackView(arrangedSubviews: [imageView, titleLabel]).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 4
        }
        
        let labelStackView = UIStackView(arrangedSubviews: [titleStackView, subLabel]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 2
        }
        
        contentView.addSubview(labelStackView)
        contentView.addSubview(surveyButton)
        
        labelStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        surveyButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }
    }
}

//MARK: Reactive
extension Reactive where Base: HomeOnboardingCell {
    var surveyButtonTap: ControlEvent<Void> {
        base.surveyButton.rx.tap
    }
}
