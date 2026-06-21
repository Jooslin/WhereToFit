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
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let arrowImageView = UIImageView(image: .arrowDown).then {
        $0.tintColor = .gray300
    }
    
    private let regularLabel = UILabel(text: "주기적으로 갑니다", config: .body14Medium, color: .gray400)
    private let reservationLabel = UILabel(text: "예약한 날이 있습니다", config: .body14Medium, color: .gray400)
    
    let facilityTextField = TouchableDesignTextField().then {
        $0.placeholder = "이용 시설 검색"
    }
    
    let programTextField = DesignTextField().then {
        $0.placeholder = "프로그램명을 입력해주세요"
    }
    
    let sportsTextField = TouchableDesignTextField().then {
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
    
    let dateTextField = TouchableDesignTextField().then {
        $0.placeholder = "날짜를 선택해주세요"
    }
    
    let startTimeTextField = TouchableDesignTextField().then {
        $0.placeholder = "시간을 선택해주세요"
    }
    
    let endTimeTextField = TouchableDesignTextField().then {
        $0.placeholder = "시간을 선택해주세요"
    }
    
    let registerButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "등록하기"
    }
    
    private(set) lazy var buttonStack = makeVerticalStackView(title: "요일 선택", view: weekdayButtons).then {
        $0.alignment = .leading
        $0.isHidden = true
    }
    private(set) lazy var dateStack = makeVerticalStackView(title: "날짜 선택", view: dateTextField).then {
        $0.isHidden = true
    }
    private(set) lazy var startTimeStack = makeVerticalStackView(title: "시작 시간 (선택)", view: startTimeTextField).then {
        $0.isHidden = true
    }
    private(set) lazy var endTimeStack = makeVerticalStackView(title: "끝나는 시간 (선택)", view: endTimeTextField).then {
        $0.isHidden = true
    }
    private lazy var timeStack = UIStackView(arrangedSubviews: [startTimeStack, endTimeStack]).then {
        $0.axis = .horizontal
        $0.spacing = 22
        $0.distribution = .fillEqually
        $0.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateScheduleInputVisibility() {
        let isRegularSelected = regularButton.isSelected
        let isReservationSelected = reservationButton.isSelected
        let shouldShowTime = isRegularSelected || isReservationSelected
        
        buttonStack.isHidden = !isRegularSelected
        dateStack.isHidden = !isReservationSelected
        timeStack.isHidden = !shouldShowTime
        startTimeStack.isHidden = !shouldShowTime
        endTimeStack.isHidden = !shouldShowTime
    }
}

//MARK: Layout
extension ProgramRegisterView {
    private func setLayout() {
        let facilityStack = makeVerticalStackView(title: "시설", view: facilityTextField)
        let sportsStack = makeVerticalStackView(title: "운동 종목", view: sportsTextField)
        let programStack = makeVerticalStackView(title: "프로그램", view: programTextField)
        
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
        
        let formStack = UIStackView(arrangedSubviews: [
            facilityStack,
            sportsStack,
            programStack,
            regularStack,
            reservationStack,
            buttonStack,
            dateStack,
            timeStack
        ]).then {
            $0.axis = .vertical
            $0.spacing = 20
        }
        
        addSubview(titleView)
        addSubview(scrollView)
        addSubview(registerButton)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(formStack)
        
        formStack.setCustomSpacing(8, after: regularStack)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(registerButton.snp.top).inset(8)
        }
        
        registerButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        formStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        sportsTextField.addSubview(arrowImageView)
        
        arrowImageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.verticalEdges.trailing.equalToSuperview().inset(12)
        }
    }
    
    private func makeVerticalStackView(title: String, view: UIView) -> UIStackView {
        let titleLabel = UILabel(text: title, config: .body14Medium, color: .gray600)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, view]).then {
            $0.axis = .vertical
            $0.alignment = .fill
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
