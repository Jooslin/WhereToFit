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
    var onSelectFacility: ((String?, String) -> Void)? // ProgramRegisterReactor 데이터 전달용 클로저
    let searchView = FacilitySearchView()
    
    override func loadView() {
        view = searchView
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
        
        Observable.just(FacilitySearchReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchView.rx.searchText
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map(FacilitySearchReactor.Action.searchTextChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchView.rx.listCellSelected
            .subscribe(onNext: { [weak self] id in
                self?.onSelectFacility?(id.id, id.name)
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
        
        searchView.rx.emptyButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withLatestFrom(reactor.state.map(\.searchText))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .subscribe(onNext: { [weak self] searchText in
                self?.onSelectFacility?(nil, searchText)
                self?.steps.accept(AppStep.pageBack)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: FacilitySearchReactor) {
        let searchItems = reactor.state
            .map { state -> [FacilitySearchView.Item] in
                state.searchResults.map { result in
                    FacilitySearchView.Item(
                        id: result.id,
                        name: result.name,
                        address: result.address,
                        distanceText: result.distanceText
                    )
                }
            }
            .distinctUntilChanged()
        
        searchItems
            .bind(onNext: { [searchView] items in
                searchView.setSnapshot(with: items)
            })
            .disposed(by: disposeBag)
        
        let emptyState = reactor.state
            .map(FacilitySearchEmptyState.init)
            .distinctUntilChanged()
        
        emptyState
            .bind(onNext: { [searchView] state in
                searchView.setEmptyState(isHidden: !state.isVisible, searchText: state.searchText)
            })
            .disposed(by: disposeBag)
    }
}

private struct FacilitySearchEmptyState: Equatable {
    let isVisible: Bool
    let searchText: String
    
    nonisolated init(state: FacilitySearchReactor.State) {
        isVisible = state.shouldShowEmptyState
        searchText = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    FacilitySearchViewController()
}
