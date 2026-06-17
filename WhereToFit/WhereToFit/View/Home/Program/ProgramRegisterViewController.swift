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

final class ProgramRegisterViewController: BaseViewController<ProgramRegisterReactor> {
    private let registerView = ProgramRegisterView()
    
    override func loadView() {
        view = registerView
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
    }
    
    private func bindState(reactor: ProgramRegisterReactor) {
        
    }
}
