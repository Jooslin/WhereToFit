//
//  ProgramFacilityListCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import SnapKit
import Then

final class ProgramFacilityListCell: UICollectionViewListCell {
    let imageView = RoundImageView(image: .locationPinFilled, type: .circle).then {
        $0.backgroundColor = .gray50
        $0.tintColor = .gray400
    }
    
    let nameLabel = UILabel(config: .body16Medium, lines: 1)
    let addressLabel = UILabel(config: .body12Regular, color: .gray500)
    let distanceLabel = UILabel(config: .body12Regular, color: .gray600)
    
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
extension ProgramFacilityListCell {
    func configure(_ location: Location) {
        
    }
    
    func hideSeparateBar(_ isLast: Bool) {
        separateBar.isHidden = isLast
    }
}

//MARK: Layout
extension ProgramFacilityListCell {
    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel]).then {
            $0.axis = .vertical
            $0.spacing = 2
            $0.alignment = .leading
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, labelStack, distanceLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }
        
        addSubview(stackView)
        contentView.addSubview(separateBar)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.verticalEdges.equalToSuperview().inset(16)
        }
        
        separateBar.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(4)
            $0.height.equalTo(0.5)
        }
    }
}
