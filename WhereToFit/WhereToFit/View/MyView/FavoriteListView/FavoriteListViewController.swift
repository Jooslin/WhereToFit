//
//  FavoriteListViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class FavoriteListViewController: BaseViewController<FavoriteListReactor> {
    let favoriteProgramsView = FavoriteListView()

    override func loadView() {
        view = favoriteProgramsView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reactor?.action.onNext(.refresh)
    }

    override func bind(reactor: FavoriteListReactor) {
        favoriteProgramsView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        favoriteProgramsView.favoriteButtonTapped = { [weak reactor] item in
            reactor?.action.onNext(.removeFavorite(item))
        }

        favoriteProgramsView.segmentedControl.rx
            .controlEvent(.valueChanged)
            .map { [weak self] in
                FavoriteListReactor.Action.selectTab(self?.favoriteProgramsView.selectedTab ?? .facility)
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
