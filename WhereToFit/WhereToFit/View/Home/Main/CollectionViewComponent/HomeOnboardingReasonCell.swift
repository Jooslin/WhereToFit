//
//  HomeOnboardingReasonCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import UIKit
import SnapKit
import Then

final class HomeOnboardingReasonCell: UICollectionViewCell {
    private let titleLabel = ColoredLabel(text: "AI 추천 이유", style: .fill).then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 4
        $0.apply(font: .systemFont(ofSize: 12, weight: .semibold), color: .primary400)
    }
    private let descriptionLabel = UILabel(config: .body14Regular, color: .gray700)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.backgroundColor = .primary25
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        // setLayout
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.alignment = .leading
        }
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeOnboardingReasonCell {
    func configure(_ text: String) {
        descriptionLabel.text = text
    }
}
