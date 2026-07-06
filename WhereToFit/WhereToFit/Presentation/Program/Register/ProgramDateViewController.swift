//
//  ProgramDateViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/18/26.
//

import UIKit
import Then
import SnapKit
import RxSwift
import ReactorKit
import RxCocoa

final class ProgramDateViewController: BaseViewController<ProgramDateReactor> {
    var onSelectDate: (([Date]) -> Void)? // ProgramRegisterReactor 데이터 전달용 클로저
    
    private let calendarView = UICalendarView()
    private lazy var multiSelection = UICalendarSelectionMultiDate(delegate: self)
    
    private let resetButton = DesignButton(config: .largeBorderGray).then {
        $0.title = "초기화"
    }
    private let applyButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "적용"
    }
    
    // delegate 전달용 이벤트
    private let selectedDateRelay = PublishRelay<DateComponents>()
    private let deselectedDateRelay = PublishRelay<DateComponents>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set Attributes
        view.backgroundColor = .white
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.tintColor = .primary400
        calendarView.backgroundColor = .clear
        calendarView.selectionBehavior = multiSelection
        
        //set Layout
        let buttonStack = UIStackView(arrangedSubviews: [resetButton, applyButton]).then {
            $0.axis = .horizontal
            $0.spacing = 19
            $0.distribution = .fillProportionally
        }
        
        view.addSubview(calendarView)
        view.addSubview(buttonStack)
        
        calendarView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(calendarView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
        }
    }
    
    override func bind(reactor: ProgramDateReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: ProgramDateReactor) {
        selectedDateRelay
            .map { ProgramDateReactor.Action.selectDate($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        deselectedDateRelay
            .map { ProgramDateReactor.Action.deselectDate($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        resetButton.rx.tap
            .do(onNext: { [weak self] in
                self?.clearSelectedDates()
            })
            .map { ProgramDateReactor.Action.resetDates }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        applyButton.rx.tap
            .withLatestFrom(reactor.state.map(\.dates))
            .bind(with: self) { owner, dates in
                owner.onSelectDate?(dates.sorted())
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: ProgramDateReactor) {
    }
}

extension ProgramDateViewController: UICalendarSelectionMultiDateDelegate {
    func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
        selectedDateRelay.accept(dateComponents)
    }
    
    func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
        deselectedDateRelay.accept(dateComponents)
    }
    
    
}

private extension ProgramDateViewController {
    func clearSelectedDates() {
        multiSelection.setSelectedDates([], animated: true)
    }
}

#Preview {
    ProgramDateViewController()
}
