//
//  ProgramDateViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/18/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class ProgramDateViewController: BaseViewController<ProgramDateReactor> {
    var onSelectDate: (([Date]) -> Void)? // ProgramRegisterReactor 데이터 전달용 클로저
    
    private let calendarView = UICalendarView()
    private lazy var multiSelection = UICalendarSelectionMultiDate(delegate: self)
    
    // delegate 전달용 이벤트
    private let selectedDateRelay = PublishRelay<DateComponents>()
    private let deselectedDateRelay = PublishRelay<DateComponents>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

#Preview {
    ProgramDateViewController()
}
