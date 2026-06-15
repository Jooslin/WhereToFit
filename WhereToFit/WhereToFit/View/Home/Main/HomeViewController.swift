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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            .map { AppStep.locationSetting }
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
