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
    let locationView = HomeLocationView()
    
    override func loadView() {
        view = locationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func bind(reactor: HomeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        locationView.rx.searchBarTap
            .subscribe(onNext: { [weak self] in
                self?.present()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeReactor) {
        let state = reactor.state
            .asDriver(onErrorJustReturn: .init())
        
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
