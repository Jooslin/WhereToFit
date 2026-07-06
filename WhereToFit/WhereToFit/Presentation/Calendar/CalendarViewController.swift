//
//  CalendarViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import SwiftUI
import Then
import UIKit

final class CalendarViewController: BaseViewController<CalendarReactor> {
    let calendarView = CalendarView()
    private var exerciseItems: [CalendarReactor.ExerciseItem] = []
    private let reportHostingController = UIHostingController(
        rootView: ReportContentSwiftUIView(report: .empty)
    )
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

    override func viewDidLoad() {
        super.viewDidLoad()

        installReportHostingController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard calendarView.isReportContentSelected() else { return }
        reactor?.action.onNext(.reportTabSelected)
    }

    override func bind(reactor: CalendarReactor) {
        Observable.just(())
            .map { CalendarReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        calendarView.rx.selectedSegmentIndex
            .distinctUntilChanged()
            .bind(with: self) { owner, selectedIndex in
                let mode: CalendarView.ContentMode = selectedIndex == 0 ? .calendar : .report
                owner.calendarView.updateContentMode(mode)

                guard mode == .report else { return }
                reactor.action.onNext(.reportTabSelected)
            }
            .disposed(by: disposeBag)

        calendarView.rx.todayButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { CalendarReactor.Action.moveToToday }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        calendarView.rx.dateSelected
            .map { CalendarReactor.Action.selectDate($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        calendarView.rx.weightCardTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarWeightInput)
            }
            .disposed(by: disposeBag)

        calendarView.rx.conditionCardTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
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

        reactor.state
            .map(\.report)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, report in
                owner.updateReport(report)
            }
            .disposed(by: disposeBag)

        reactor.pulse(\.$error)
            .compactMap { $0 }
            .map { AppStep.alert(title: $0.0, message: $0.1) }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

private extension CalendarViewController {
    func installReportHostingController() {
        guard reportHostingController.parent == nil else { return }

        reportHostingController.view.backgroundColor = .clear
        if #available(iOS 16.0, *) {
            reportHostingController.sizingOptions = [.intrinsicContentSize]
        }

        addChild(reportHostingController)
        calendarView.installReportContentView(reportHostingController.view)
        reportHostingController.didMove(toParent: self)
    }

    func updateReport(_ report: CalendarReactor.ReportState) {
        reportHostingController.rootView = ReportContentSwiftUIView(report: report)
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
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.calendarExerciseRecordInput)
            }
            .disposed(by: footerView.disposeBag)

        return footerView
    }
}
