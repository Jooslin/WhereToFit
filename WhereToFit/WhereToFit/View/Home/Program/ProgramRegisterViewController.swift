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
        
        registerView.sportsTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.sportsCategorySelection }
            .bind(to: steps)
            .disposed(by: disposeBag)

        registerView.programTextField.rx.controlEvent(.editingChanged)
            .withLatestFrom(registerView.programTextField.rx.text.orEmpty)
            .map(ProgramRegisterReactor.Action.updateProgramName)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        registerView.programTextField.rx.controlEvent(.editingDidEnd)
            .map { ProgramRegisterReactor.Action.finishProgramDirectInput }
            .bind(to: reactor.action)
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
        
        reactor.state
            .map(\.sportsCategoryDisplayName)
            .distinctUntilChanged()
            .bind(to: registerView.sportsTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.programOptions)
            .distinctUntilChanged()
            .bind(with: self) { owner, options in
                owner.updateProgramMenu(options: options)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.programName)
            .distinctUntilChanged()
            .bind(with: self) { owner, programName in
                guard owner.registerView.programTextField.isFirstResponder == false else {
                    return
                }

                owner.registerView.programTextField.text = programName
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isProgramDirectInputEnabled)
            .distinctUntilChanged()
            .bind(with: self) { owner, isEnabled in
                owner.registerView.programMenuButton.isHidden = isEnabled

                if isEnabled {
                    owner.registerView.programTextField.becomeFirstResponder()
                }
            }
            .disposed(by: disposeBag)
    }
}

private extension ProgramRegisterViewController {
    func updateProgramMenu(options: [ProgramRegisterReactor.ProgramOption]) {
        var actions = options.map { option in
            UIAction(title: option.name) { [weak self] _ in
                self?.reactor?.action.onNext(.selectProgram(option))
            }
        }

        actions.append(
            UIAction(title: "직접 입력") { [weak self] _ in
                self?.reactor?.action.onNext(.selectDirectProgramInput)
            }
        )

        registerView.programMenuButton.menu = UIMenu(children: actions)
    }
}
