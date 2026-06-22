//
//  FavoriteListViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class FavoriteListViewController: BaseViewController<FavoriteListReactor> {
    let favoriteProgramsView = FavoriteListView()
    var favoriteItemSelected: ((FavoriteListReactor.FavoriteItem) -> Void)?

    override func loadView() {
        view = favoriteProgramsView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reactor?.action.onNext(.refresh)
    }

    override func bind(reactor: FavoriteListReactor) {
        favoriteProgramsView.titleView.rx.leftButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        favoriteProgramsView.favoriteButtonTapped = { [weak self] item in
            self?.presentRemoveFavoriteAlert(item)
        }

        favoriteProgramsView.itemSelected = { [weak self] item in
            self?.favoriteItemSelected?(item)
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

private extension FavoriteListViewController {
    func presentRemoveFavoriteAlert(_ item: FavoriteListReactor.FavoriteItem) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: "찜 목록에서 삭제할까요?",
            message: "\(item.name)을(를) 찜 목록에서 삭제합니다.",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let removeAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.removeFavorite(item))
        }

        alert.addAction(cancelAction)
        alert.addAction(removeAction)
        present(alert, animated: true)
    }
}
