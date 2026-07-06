//
//  HomeLocationEditListCell.swift
//  WhereToFit
//
//  Created by 변예린 on 6/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class LocationEditListCell: LocationListCell {
    private(set) var disposeBag = DisposeBag()
    
    let editButton = DesignButton(config: .additional).then {
        $0.title = "수정"
    }
    
    let deleteButton = DesignButton(config: .additional).then {
        $0.title = "삭제"
    }
    
    let separateBar = UIView().then {
        $0.backgroundColor = .gray100
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(separateBar)
        
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(24)
            $0.top.equalToSuperview().offset(20)
        }
        
        separateBar.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(4)
            $0.height.equalTo(0.5)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separateBar.layer.cornerRadius = separateBar.bounds.height / 2
        separateBar.clipsToBounds = true
    }
    
    override func setAttributes() {
        let buttonStackView = UIStackView(arrangedSubviews: [editButton, deleteButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .leading

        }
        
        let buttonLabelStack = UIStackView(arrangedSubviews: [labelStack, buttonStackView]).then {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .leading
        }
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(buttonLabelStack)
        stackView.addArrangedSubview(checkImageView)
        
        stackView.do {
            $0.axis = .horizontal
            $0.spacing = 12
            $0.alignment = .center
            
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }
    
    override func configure(_ location: UserLocation) {
        super.configure(location)
        contentView.backgroundColor = .white
    }
}

extension LocationEditListCell {
    func hideSeparateBar(_ isLast: Bool) {
        separateBar.isHidden = isLast
    }
}

//MARK: Reactive
extension Reactive where Base: LocationEditListCell {
    var editButtonTap: ControlEvent<Void> {
        base.editButton.rx.tap
    }
    
    var deleteButtonTap: ControlEvent<Void> {
        base.deleteButton.rx.tap
    }
}
