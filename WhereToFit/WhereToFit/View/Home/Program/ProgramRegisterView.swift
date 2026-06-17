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
    
    let regularButton = IconButton(config: .icon, style: .icon).then {
        $0.normalImage = .checkOff
        $0.selectedImage = .checkOn
    }
    let reservationButton = IconButton(config: .icon, style: .icon).then {
        $0.normalImage = .checkOff
        $0.selectedImage = .checkOn
    }
    
    private(set) lazy var weekdayButtons = generateWeekdayButtonStack()
    
    let dateTextField = DesignTextField().then {
        $0.placeholder = "날짜를 선택해주세요"
    }
    
    let startTimeTextField = DesignTextField().then {
        $0.placeholder = "시간을 선택해주세요"
    }
    
    let endTimeTextField = DesignTextField().then {
        $0.placeholder = "시간을 선택해주세요"
    }
}

//MARK: Layout
extension ProgramRegisterView {
    private func setLayout() {
        let facilityStack = makeVerticalStackView(title: "시설", view: facilityTextField)
        let programStack = makeVerticalStackView(title: "프로그램", view: facilityTextField)
        let sportsStack = makeVerticalStackView(title: "운동 종목", view: facilityTextField)
        
        let regularStack = UIStackView(arrangedSubviews: [regularButton, regularLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        let reservationStack = UIStackView(arrangedSubviews: [reservationButton, reservationLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        let dateStack = makeVerticalStackView(title: "날짜 선택", view: dateTextField)
        let startTimeStack = makeVerticalStackView(title: "시작 시간 (선택)", view: startTimeTextField)
        let endTimeStack = makeVerticalStackView(title: "끝나는 시간 (선택)", view: endTimeTextField)
    }
    
    private func makeVerticalStackView(title: String, view: UIView) -> UIStackView {
        let titleLabel = UILabel(text: title, config: .body14Medium, color: .gray600)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, view]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 6
        }
        
        return stackView
    }
    
    private func generateWeekdayButtonStack() -> UIStackView {
        let buttons = Weekday.allCases.reduce([DesignButton]()) { arr, weekday in
            let button = DesignButton(config: .chip, selectedConfig: .selectedChip).then {
                $0.title = weekday.title
                $0.tag = weekday.rawValue
            }
            
            return arr + [button]
        }
        
        let stackView = UIStackView(arrangedSubviews: buttons).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .leading
        }
        
        return stackView
    }
}

extension Reactive where Base: ProgramRegisterView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.leftButton.rx.tap
    }
}
