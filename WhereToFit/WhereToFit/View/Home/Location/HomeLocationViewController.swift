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
    private let locationView = HomeLocationView()
    
    override func loadView() {
        view = locationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locations: [Location] = [
            Location(
                icon: .homeFilled,
                name: "우리동네체육관",
                address: "경상북도 구미시 송정대로 55",
                isSelected: true,
                latitude: 36.1195,
                longitude: 128.3446
            ),
            Location(
                icon: .locationPin,
                name: "구미시민운동장",
                address: "경상북도 구미시 박정희로 375",
                isSelected: false,
                latitude: 36.1107,
                longitude: 128.3828
            ),
            Location(
                icon: .locationPin,
                name: "금오산도립공원",
                address: "경상북도 구미시 금오산로 400",
                isSelected: false,
                latitude: 36.1132,
                longitude: 128.3087
            )
        ]
        
        locationView.setSnapshot(with: locations)
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
