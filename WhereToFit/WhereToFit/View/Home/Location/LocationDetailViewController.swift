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
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func bind(reactor: LocationDetailReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: LocationDetailReactor) {
        detailView.rx.backButtonTap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: LocationDetailReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        state.compactMap(\.selectedAddress)
            .drive(
                with: detailView,
                onNext: { detailView, address in
                    detailView.addressTextField.text = address
                    detailView.registerButton.title = "등록하기"
                })
            .disposed(by: disposeBag)
        
        state.compactMap(\.selectedLocation)
            .drive(
                with: detailView,
                onNext: { detailView, location in
                    detailView.addressTextField.text = location.name
                    
                    detailView.nameTextField.text = location.name
                    
                    detailView.registerButton.title = "수정하기"
                })
            .disposed(by: disposeBag)
        
    }
}
