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

final class HomeLocationViewController: BaseViewController<HomeReactor> {
    private let homeView = HomeLocationView()
    
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
        
    }
    
    private func bindState(reactor: HomeReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
    }
}

#Preview {
    HomeLocationViewController()
}
