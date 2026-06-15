//
//  HomeLocationViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/12/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class LocationViewController: BaseViewController<LocationReactor> {
    let locationView = LocationView()
    
    private let selectedAddressRelay = PublishRelay<String>()
    
    override func loadView() {
        view = locationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func bind(reactor: LocationReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: LocationReactor) {
        self.rx.viewWillAppear
            .map { LocationReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        locationView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        locationView.rx.editButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.locationEdit }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        locationView.rx.searchBarTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { `self`, _ in
                self.presentPostCodeSelection()
            })
            .disposed(by: disposeBag)
        
        selectedAddressRelay
            .map { address in
                AppStep.locationDetail(.create(address: address))
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: LocationReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        state.map(\.locations)
            .drive(
                with: locationView,
                onNext: { locationView, locations in
                    locationView.setSnapshot(with: locations)
                })
            .disposed(by: disposeBag)
    }
}

extension LocationViewController {
    private func presentPostCodeSelection() {
        let vc = KakaoPostCodeViewController()
        vc.onSelectAddress = { [weak self] address in
            self?.selectedAddressRelay.accept(address)
        }
        self.present(vc, animated: true)
    }
}

#Preview {
    LocationViewController()
}
