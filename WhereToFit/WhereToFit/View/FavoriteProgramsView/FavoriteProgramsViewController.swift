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
    }
}
