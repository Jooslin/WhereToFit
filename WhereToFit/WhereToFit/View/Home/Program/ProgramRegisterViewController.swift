//
//  ProgramRegisterViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa
import SnapKit
import Then

final class ProgramRegisterViewController: BaseViewController<ProgramRegisterReactor> {
    private let registerView = ProgramRegisterView()
    
    override func loadView() {
        view = registerView
    }
    
    override func viewWillAppear(_ animate: Bool) {
        super.viewWillAppear(animate)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func bind(reactor: ProgramRegisterReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: ProgramRegisterReactor) {
        // TitleView
        registerView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        // button
        registerView.facilityTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.facilitySearch }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        registerView.dateTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.selectDate }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        registerView.regularButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [registerView] in
                registerView.regularButton.isSelected.toggle()
                registerView.updateScheduleInputVisibility()
            })
            .disposed(by: disposeBag)
        
        registerView.reservationButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [registerView] in
                registerView.reservationButton.isSelected.toggle()
                registerView.updateScheduleInputVisibility()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: ProgramRegisterReactor) {
        reactor.state
            .map(\.facilityName)
            .distinctUntilChanged()
            .bind(to: registerView.facilityTextField.rx.text)
            .disposed(by: disposeBag)
    }
}
