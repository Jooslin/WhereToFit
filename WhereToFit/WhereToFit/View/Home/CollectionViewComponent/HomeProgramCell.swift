//
//  HomeProgramCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/3/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxSwift

final class HomeProgramCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    fileprivate let imageView = ProgramImageView(image: nil)
    private let matchLabel = UILabel(config: .body12Regular) //TODO: CustomLabel로 수정 필요
    private let placeLabel = UILabel(config: .body12Regular) //TODO: CustomLabel로 수정 필요
    private let nameLabel = UILabel(config: .body16Medium)
    private let facilityLabel = UILabel(config: .body12Regular)
    
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
        disposeBag = DisposeBag()
        
        // 이미지 초기화
        imageView.image = nil
    }
}

//MARK: Configure
extension HomeProgramCell {
    func configure(image: UIImage?, text: String) {
        
    }
}

//MARK: Layout
extension HomeProgramCell {
    private func setLayout() {
        let coloredLabelStackView = UIStackView(arrangedSubviews: [matchLabel, placeLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.alignment = .center

            matchLabel.setContentHuggingPriority(.required, for: .horizontal)
            matchLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        contentView.addSubview(imageView)
        contentView.addSubview(coloredLabelStackView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(facilityLabel)
        
        imageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }
        
        coloredLabelStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(coloredLabelStackView.snp.bottom).offset(2)
            $0.horizontalEdges.equalToSuperview()
        }
        
        facilityLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }
}

//MARK: Reactive
extension Reactive where Base: HomeProgramCell {
    var favoriteButtonTap: ControlEvent<Void> {
        base.imageView.favoriteButton.rx.tap
    }
}
