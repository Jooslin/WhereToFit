//
//  HomeLocationListCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/12/26.
//

import UIKit
import SnapKit
import Then

final class HomeLocationListCell: UICollectionViewListCell {
    let imageView = UIImageView().then {
        $0.tintColor = .gray900
    }
    let nameLabel = UILabel(config: .body15)
    let addressLabel = UILabel(config: .body13Regular)
    let checkImageView = UIImageView(image: .check).then {
        $0.tintColor = .primary400
        $0.isHidden = true
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
        addressLabel.text = ""
        imageView.image = nil
    }
}

extension HomeLocationListCell {
    func configure(_ location: Location) {
        imageView.image = location.icon
        nameLabel.text = location.name
        addressLabel.text = location.address
        checkImageView.isHidden = !location.isSelected
    }
}

extension HomeLocationListCell {
    private func setLayout() {
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel]).then {
            $0.axis = .vertical
            $0.spacing = 2
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, labelStack, checkImageView]).then {
            $0.axis = .horizontal
            $0.spacing = 12
            $0.alignment = .center
            
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(8)
            $0.verticalEdges.equalToSuperview().inset(20)
        }
        
        imageView.snp.makeConstraints {
            $0.height.width.equalTo(24)
        }
        
        checkImageView.snp.makeConstraints {
            $0.height.width.equalTo(24)
        }
    }
}
