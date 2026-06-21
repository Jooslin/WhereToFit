//
//  CalendarViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import Then
import UIKit

final class CalendarViewController: BaseViewController<CalendarReactor> {
    let calendarView = CalendarView()
    private var exerciseItems: [CalendarReactor.ExerciseItem] = []
    private let selectedDateFormatter = DateFormatter().then {
        $0.locale = Locale(identifier: "ko_KR")
        $0.dateFormat = "M월 d일 EEEE"
    }

    override func loadView() {
        // 캘린더 레이아웃 고정
        calendarView.minimumContentSizeCategory = .extraSmall
        calendarView.maximumContentSizeCategory = .extraSmall
        calendarView.setExerciseCollectionViewDataSource(self)
        view = calendarView
    }

    override func bind(reactor: CalendarReactor) {
        calendarView.rx.selectedSegmentIndex
            .distinctUntilChanged()
            .map { $0 == 0 ? CalendarView.ContentMode.calendar : .report }
            .bind(with: self) { owner, mode in
                owner.calendarView.updateContentMode(mode)
            }
            .disposed(by: disposeBag)

        calendarView.rx.todayButtonTap
            .map { CalendarReactor.Action.moveToToday }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        calendarView.rx.dateSelected
            .map { CalendarReactor.Action.selectDate($0) }
            .bind(to: reactor.action)
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

        reactor.state
            .map(\.selectedDate)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, selectedDate in
                owner.calendarView.updateSelectedDate(
                    selectedDate,
                    text: owner.selectedDateFormatter.string(from: selectedDate)
                )
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

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter,
              let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CalendarExerciseFooterView.reuseIdentifier,
                for: indexPath
              ) as? CalendarExerciseFooterView else {
            return UICollectionReusableView()
        }

        footerView.rx.recordButtonTap
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarExerciseRecordInput)
            }
            .disposed(by: footerView.disposeBag)

        return footerView
    }
}
