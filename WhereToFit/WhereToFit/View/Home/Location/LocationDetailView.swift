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
    let titleView = TitleView(text: "위치 상세", leftButtonImage: .arrowLeft)
    let addressLabel = UILabel(config: .body14Medium)
    let addressTextField = DesignTextField()
//    let myHomeButton = IconButton(image: .home, title: "우리집").then {
//        
//    }
//    let officeButton = IconButton(image: .home, title: "회사")
//    let addButton = IconButton(image: .locationPin, title: "추가")
    let nameTextField = DesignTextField().then {
        $0.placeholder = "장소 이름을 입력해주세요"
    }
}
