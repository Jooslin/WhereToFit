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

final class LocationDetailViewController: BaseViewController<LocationReactor> {
    let detailView = LocationDetailView()
    
    override func loadView() {
        view = detailView
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
            .map { LocationReactor.Action.loadItems }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.backButtonTap
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: LocationReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        
    }
}
