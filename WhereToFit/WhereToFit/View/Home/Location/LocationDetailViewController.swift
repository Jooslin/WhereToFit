//
//  LocationDetailViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class LocationDetailViewController: BaseViewController<LocationDetailReactor> {
    let detailView = LocationDetailView()
    
    private let selectedAddressRelay = PublishRelay<String>()
    
    override func loadView() {
        view = detailView
    }
    
    override func bind(reactor: LocationDetailReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: LocationDetailReactor) {
        detailView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        detailView.rx.addressTextFieldTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { `self`, _ in
                self.detailView.addressTextField.resignFirstResponder()
                self.presentPostCodeSelection()
            })
            .disposed(by: disposeBag)
        
        selectedAddressRelay
            .map { LocationDetailReactor.Action.updateAddress($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.homeButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.myHome) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.officeButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.office) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.addButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.additional) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
//        detailView.registerButton.rx.tap
//            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
//            .map { }
    }
    
    private func bindState(reactor: LocationDetailReactor) {
        let state = reactor.state
            .asDriver(
                onErrorJustReturn: .init(address: "", name: "")
            )
        
        state.map(\.address)
            .drive(
                with: detailView,
                onNext: { detailView, address in
                    detailView.addressTextField.text = address
                }
            )
            .disposed(by: disposeBag)
        
        state.map(\.name)
            .drive(
                with: detailView,
                onNext: { detailView, name in
                    detailView.nameTextField.text = name
                }
            )
            .disposed(by: disposeBag)
        
        state.map(\.registerButtonTitle)
            .distinctUntilChanged()
            .drive(
                with: detailView,
                onNext: { detailView, title in
                    detailView.registerButton.title = title
                }
            )
            .disposed(by: disposeBag)
        
        state.map(\.buttonType)
            .drive(
                with: detailView,
                onNext: { detailView, buttonType in
                    detailView.configureButtonType(buttonType)
                }
            )
            .disposed(by: disposeBag)
    }
}

extension LocationDetailViewController {
    private func presentPostCodeSelection() {
        let vc = KakaoPostCodeViewController()
        vc.onSelectAddress = { [weak self] address in
            self?.selectedAddressRelay.accept(address)
        }
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: false)
    }
}
