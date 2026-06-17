//
//  ProgramRegisterView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import Then

final class ProgramRegisterView: UIView {
    fileprivate let titleView = TitleView(text: "프로그램 등록", leftButtonImage: .arrowLeft)
    
    private let facilityTitleLabel = UILabel(text: "시설", config: .body14Medium, color: .gray600)
    private let programTitleLabel = UILabel(text: "프로그램", config: .body14Medium, color: .gray600)
    private let sportsTitleLabel = UILabel(text: "운동 종목", config: .body14Medium, color: .gray600)
    private let regularLabel = UILabel(text: "주기적으로 갑니다", config: .body14Medium, color: .gray400)
    private let reservationLabel = UILabel(text: "예약한 날이 있습니다", config: .body14Medium, color: .gray400)
    
    let facilityTextField = DesignTextField().then {
        $0.placeholder = "이용 시설 검색"
    }
    
    let programTextField = DesignTextField().then {
        $0.placeholder = "프로그램명을 입력해주세요"
    }
    
    let sportsTextField = DesignTextField().then {
        $0.placeholder = "운동 종목을 선택해주세요"
    }
    
    //TODO: IconButton 이니셜라이저 수정 필요
    let regularButton = IconButton(image: .checkOff, selectedImage: .checkOn)
    let reservationButton = IconButton(image: .checkOff, selectedImage: .checkOn)
    
}

extension Reactive where Base: ProgramRegisterView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.leftButton.rx.tap
    }
}
