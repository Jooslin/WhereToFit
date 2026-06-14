//
//  CalendarViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class CalendarViewController: BaseViewController<CalendarReactor> {
    let calendarView = CalendarView()

    override func loadView() {
        view = calendarView
    }

    override func bind(reactor: CalendarReactor) {
        calendarView.rx.weightCardTap
            .bind(with: self) { owner, _ in
                owner.presentWeightInputSheet(currentWeight: reactor.currentState.weight)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.weight)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, weight in
                owner.calendarView.updateWeight(weight)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.exerciseItems)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, items in
                owner.calendarView.updateExerciseItems(items)
            }
            .disposed(by: disposeBag)
    }
}

private extension CalendarViewController {
    func presentWeightInputSheet(currentWeight: CalendarReactor.WeightValue) {
        let viewController = WeightInputViewController(currentWeight: currentWeight)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        viewController.onSave = { [weak self] weight in
            self?.reactor?.action.onNext(.updateWeight(weight))
        }

        present(viewController, animated: true)
    }
}
