//
//  LocationDetailView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/14/26.
//

import UIKit
import Then
import SnapKit
import RxCocoa
import RxSwift

final class LocationDetailView: UIView {
    fileprivate let titleView = TitleView(text: "위치 상세", leftButtonImage: .arrowLeft)
    private let addressLabel = UILabel(text: "주소", config: .body14Medium, color: .gray600)
    let addressTextField = DesignTextField()
    let homeButton = IconButton(config: .iconAdditional, selectedConfig: .selectedIconAdditional, style: .leftImage, iconSize: .tiny).then {
        $0.normalImage = .home
        $0.selectedImage = .homeFilled
        $0.title = "우리집"
    }
    let officeButton = IconButton(config: .iconAdditional, selectedConfig: .selectedIconAdditional, style: .leftImage, iconSize: .tiny).then {
        $0.normalImage = .home
        $0.selectedImage = .homeFilled
        $0.title = "회사"
    }
    let addButton = IconButton(config: .iconAdditional, selectedConfig: .selectedIconAdditional, style: .leftImage, iconSize: .tiny).then {
        $0.normalImage = .locationPin
        $0.selectedImage = .locationPinFilled
        $0.title = "추가"
    }
    let nameTextField = DesignTextField().then {
        $0.placeholder = "장소 이름을 입력해주세요"
        $0.isHidden = true
    }
    
    let registerButton = DesignButton(config: .largeFilledBlue)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LocationDetailView {
    func configureButton(_ location: Location) {
        switch location.buttonType {
        case .myHome:
            homeButton.isSelected = true
            nameTextField.isHidden = true
        case .office:
            officeButton.isSelected = true
            nameTextField.isHidden = true
        case .additional:
            addButton.isSelected = true
            nameTextField.isHidden = false
            nameTextField.text = location.name
        }
    }
}

extension LocationDetailView {
    private func setLayout() {
        let addressStack = UIStackView(arrangedSubviews: [addressLabel, addressTextField]).then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .fill
        }
        
        let buttonStack = UIStackView(arrangedSubviews: [homeButton, officeButton, addButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        let stackView = UIStackView(arrangedSubviews: [addressStack, buttonStack, nameTextField]).then {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .leading
        }
        
        addSubview(titleView)
        addSubview(stackView)
        addSubview(registerButton)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        registerButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        addressTextField.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.width.equalTo(stackView.snp.width)
        }
        
        nameTextField.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.width.equalToSuperview()
        }
    }
}

extension Reactive where Base: LocationDetailView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.leftButtonTap
    }
}
