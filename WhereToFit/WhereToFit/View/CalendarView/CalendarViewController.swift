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
    private var exerciseItems: [CalendarReactor.ExerciseItem] = []

    override func loadView() {
        calendarView.setExerciseCollectionViewDataSource(self)
        view = calendarView
    }

    override func bind(reactor: CalendarReactor) {
        calendarView.rx.todayButtonTap
            .bind(with: self) { owner, _ in
                owner.calendarView.moveToToday()
            }
            .disposed(by: disposeBag)

        calendarView.rx.weightCardTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarWeightInput)
            }
            .disposed(by: disposeBag)

        calendarView.rx.conditionCardTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarConditionInput)
            }
            .disposed(by: disposeBag)

        calendarView.rx.exerciseAddButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarExerciseRecordInput)
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
            .map(\.condition)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, condition in
                owner.calendarView.updateCondition(condition)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.exerciseItems)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, items in
                owner.exerciseItems = items
                owner.calendarView.reloadExerciseItems(count: items.count)
            }
            .disposed(by: disposeBag)
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        exerciseItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarExerciseCell.reuseIdentifier,
            for: indexPath
        ) as? CalendarExerciseCell else {
            return UICollectionViewCell()
        }

        cell.configure(item: exerciseItems[indexPath.item], hidesDivider: indexPath.item == exerciseItems.count - 1)
        return cell
    }
}
