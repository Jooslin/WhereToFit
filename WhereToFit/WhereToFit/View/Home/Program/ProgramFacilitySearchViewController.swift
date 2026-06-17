//
//  ProgramFacilitySearchViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class LocationEditViewController: BaseViewController<LocationReactor> {
    let locationView = LocationEditView()
    
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
            .map { LocationReactor.Action.loadItems }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        locationView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        locationView.rx.editButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.locationDetail(.edit($0)) }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        locationView.rx.deleteButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { location in
                print(location)
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
}
