//
//  HomeViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit

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
        
    }
    
    private func bindState(reactor: HomeReactor) {
        
    }
}

#Preview {
    HomeViewController()
}
