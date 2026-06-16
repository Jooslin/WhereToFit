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
        
        // TitleView
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
        
        // 위치 지정
        locationView.rx.listCellSelected
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationReactor.Action.selected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: LocationReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        state.map(\.data)
            .drive(
                with: locationView,
                onNext: { locationView, data in
                    locationView.setSnapshot(with: data)
                })
            .disposed(by: disposeBag)
    }
}

extension LocationViewController {
//    private func presentPostCodeSelection() {
//        let vc = KakaoPostCodeViewController()
//        vc.onSelectAddress = { [weak self] address in
//            self?.selectedAddressRelay.accept(address)
//        }
//        vc.modalPresentationStyle = .overFullScreen
//        self.present(vc, animated: false)
//    }
}

#Preview {
    LocationViewController()
}
