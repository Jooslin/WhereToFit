//
//  OnboardingFacilityCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingProgramListCell: UICollectionViewListCell {
    let imageView = UIImageView(image: .gym)
    let nameLabel = UILabel(config: .body16Medium)
    let facilityLabel = UILabel(config: .body12Regular, color: .gray500)
    let weekdayLabel = UILabel(config: .body12Regular, color: .gray500)
    let timeLabel = UILabel(config: .body12Regular, color: .gray500)
    //TODO: IconButton으로 교체 필요
    let button = UIButton().then {
        $0.setImage(.arrow, for: .normal)
    }
    
    let separateBar = UIView().then {
        $0.backgroundColor = .gray200
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        facilityLabel.text = ""
        weekdayLabel.text = ""
        timeLabel.text = ""
    }
}

extension OnboardingProgramListCell {
    func configure(_ program: Program) {
        nameLabel.text = program.className
        facilityLabel.text = program.facilityName
        weekdayLabel.text = program.days.joined()
        
        guard let startTime = program.startTime else { return }
        
        if let endTime = program.endTime {
            timeLabel.text = "\(startTime)~\(endTime)"
        } else {
            timeLabel.text = startTime
        }
    }
}

extension OnboardingProgramListCell {
    private func setLayout() {
        let timeLabelStack = UIStackView(arrangedSubviews: [weekdayLabel, timeLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            weekdayLabel.setContentHuggingPriority(.required, for: .horizontal)
            weekdayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let horizontalLabelStack = UIStackView(arrangedSubviews: [facilityLabel, separateBar, timeLabelStack]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            facilityLabel.setContentHuggingPriority(.required, for: .horizontal)
            facilityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            separateBar.setContentHuggingPriority(.required, for: .horizontal)
            separateBar.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let verticalLabelStack = UIStackView(arrangedSubviews: [nameLabel, horizontalLabelStack]).then {
            $0.axis = .vertical
            $0.spacing = 2
            $0.alignment = .fill
        }
        
        let stackView = UIStackView(arrangedSubviews: [imageView, verticalLabelStack, button]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.verticalEdges.equalToSuperview().inset(16)
        }
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        button.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
        
        separateBar.snp.makeConstraints {
            $0.width.equalTo(1)
        }
    }
}
