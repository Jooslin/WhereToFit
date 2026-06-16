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
        
        // 셀 선택
        locationView.rx.listCellSelected
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationReactor.Action.selected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 현재 위치로 지정
        locationView.rx.currentLocationButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationReactor.Action.updateSelection }
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
        
        reactor.pulse(\.$updateResult)
            .compactMap { $0 }
            .map {
                $0 ? AppStep.pageBack : AppStep.alert(title: "저장 실패", message: "현재 위치를 저장하는 데 실패했습니다.\n잠시 후 다시 시도해주세요.")
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

#Preview {
    LocationViewController()
}
