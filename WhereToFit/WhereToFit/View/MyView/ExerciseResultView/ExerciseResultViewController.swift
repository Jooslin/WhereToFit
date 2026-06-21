//
//  ExerciseResultViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class ExerciseResultViewController: BaseViewController<ExerciseResultReactor> {
    let exerciseResultView = ExerciseResultView()

    override func loadView() {
        view = exerciseResultView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reactor?.action.onNext(.viewDidLoad)
    }

    override func bind(reactor: ExerciseResultReactor) {
        Observable.just(ExerciseResultReactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        exerciseResultView.titleView.rx.leftButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        exerciseResultView.retryButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.exerciseResultRetry)
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
