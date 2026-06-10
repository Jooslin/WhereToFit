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
    }
    
    private func bindState(reactor: HomeReactor) {
        
    }
}

#Preview {
    HomeViewController()
}
