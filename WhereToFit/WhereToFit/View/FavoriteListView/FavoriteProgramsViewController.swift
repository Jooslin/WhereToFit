//
//  FavoriteProgramsViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class FavoriteProgramsViewController: BaseViewController<FavoriteProgramsReactor> {
    let favoriteProgramsView = FavoriteProgramsView()

    override func loadView() {
        view = favoriteProgramsView
    }

    override func bind(reactor: FavoriteProgramsReactor) {
        favoriteProgramsView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        favoriteProgramsView.segmentedControl.rx
            .controlEvent(.valueChanged)
            .map { [weak self] in
                FavoriteProgramsReactor.Action.selectTab(
                    FavoriteProgramsReactor.FavoriteTab(
                        segmentIndex: self?.favoriteProgramsView.segmentedControl.selectedSegmentIndex ?? 0
                    )
                )
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedTab)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, tab in
                owner.favoriteProgramsView.updateSelectedTab(tab)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.items)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, items in
                owner.favoriteProgramsView.updateItems(items)
            }
            .disposed(by: disposeBag)
    }
}
