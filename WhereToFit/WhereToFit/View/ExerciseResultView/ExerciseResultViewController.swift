//
//  ExerciseResultViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class ExerciseResultViewController: BaseViewController<ExerciseResultReactor> {
    let exerciseResultView = ExerciseResultView()

    override func loadView() {
        view = exerciseResultView
    }

    override func bind(reactor: ExerciseResultReactor) {
        exerciseResultView.titleView.rx.leftButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.summaryItems)
            .distinctUntilChanged()
            .bind(with: self) { owner, items in
                owner.exerciseResultView.updateSummaryItems(items)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.recommendationItems)
            .distinctUntilChanged()
            .bind(with: self) { owner, items in
                owner.exerciseResultView.updateRecommendationItems(items)
            }
            .disposed(by: disposeBag)
    }
}
