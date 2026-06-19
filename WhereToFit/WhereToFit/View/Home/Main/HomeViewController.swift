//
//  HomeViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class HomeViewController: BaseViewController<HomeReactor> {
    private let homeView = HomeView()
    
    override func loadView() {
        view = homeView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func bind(reactor: HomeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        self.rx.viewWillAppear
            .map { HomeReactor.Action.viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        homeView.rx.locationButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.locationSetting }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        homeView.rx.registerButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.programRegistration }
            .bind(to: steps)
            .disposed(by: disposeBag)

        homeView.rx.alarmButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.notificationCenter }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
        state.map(\.data)
            .drive(with: homeView,
                   onNext: { homeView, data in
                homeView.setSnapshot(data)
            })
            .disposed(by: disposeBag)
    }
}

#Preview {
    HomeViewController()
}
