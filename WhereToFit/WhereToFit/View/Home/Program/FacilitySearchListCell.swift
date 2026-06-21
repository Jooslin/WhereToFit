//
//  ProgramFacilityListCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import SnapKit
import Then

final class FacilitySearchListCell: UICollectionViewListCell {
    let imageBackgroundView = UIView().then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }
    
    let imageView = UIImageView(image: .locationPinFilled).then {
        $0.tintColor = .gray400
    }
    
    let nameLabel = UILabel(config: .body16Medium, lines: 1)
    let addressLabel = UILabel(config: .body12Regular, color: .gray500)
    let distanceLabel = UILabel(config: .body12Regular, color: .gray600).then {
        $0.textAlignment = .right
    }
    
    let separateBar = UIView().then {
        $0.backgroundColor = .gray100
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separateBar.layer.cornerRadius = separateBar.bounds.height / 2
        separateBar.clipsToBounds = true
    }
    
    
}

//MARK: Configure
extension FacilitySearchListCell {
    func configure(with item: FacilitySearchView.Item) {
        nameLabel.text = item.name
        addressLabel.text = item.address
        distanceLabel.text = item.distanceText
    }
    
    func hideSeparateBar(_ isLast: Bool) {
        separateBar.isHidden = isLast
    }
    
}

//MARK: Layout
extension FacilitySearchListCell {
    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel]).then {
            $0.axis = .vertical
            $0.spacing = 2
            $0.alignment = .leading
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageBackgroundView, labelStack, distanceLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
            
            labelStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
            labelStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        
        contentView.addSubview(stackView)
        contentView.addSubview(separateBar)
        imageBackgroundView.addSubview(imageView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().inset(20)
        }
        
        separateBar.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(4)
            $0.height.equalTo(0.5)
        }
        
        imageBackgroundView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.center.equalToSuperview()
        }
    }
}
