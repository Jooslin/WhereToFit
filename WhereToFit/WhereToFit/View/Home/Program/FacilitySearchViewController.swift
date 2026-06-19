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

final class FacilitySearchViewController: BaseViewController<FacilitySearchReactor> {
    var onSelectFacility: ((UUID) -> Void)? // ProgramRegisterReactor 데이터 전달용 클로저
    let searchView = FacilitySearchView()
    
    override func loadView() {
        view = searchView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let items = [
            FacilitySearchView.Item(id: UUID(), name: "올림픽수영장", address: "서울 송파구 올림픽로 424", distance: 1.0)
        ]
        
        searchView.setSnapshot(with: items)
    }
    
    override func bind(reactor: FacilitySearchReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: FacilitySearchReactor) {
        searchView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        searchView.rx.listCellSelected
            .map(\.id)
            .subscribe(onNext: { [weak self] id in
                self?.onSelectFacility?(id)
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
    }
    
    private func bindState(reactor: FacilitySearchReactor) {
        
    }
}

#Preview {
    FacilitySearchViewController()
}
