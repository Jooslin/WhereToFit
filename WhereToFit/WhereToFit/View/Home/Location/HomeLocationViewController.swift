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

final class HomeLocationViewController: BaseViewController<LocationReactor> {
    let locationView = HomeLocationView()
    
    override func loadView() {
        view = locationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        locationView.rx.searchBarTap
            .subscribe(onNext: { [weak self] in
                self?.present()
            })
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
    
    func present() {
        let vc = KakaoPostCodeViewController()
        vc.onSelectAddress = { [weak self] address in
            self?.locationView.searchBar.text = address
        }
        self.present(vc, animated: true)
    }
}

#Preview {
    HomeLocationViewController()
}
