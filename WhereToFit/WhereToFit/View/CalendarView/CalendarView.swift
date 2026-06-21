//
//  CalendarView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CalendarView: UIView {
    enum ContentMode {
        case calendar
        case report
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    private let contentView = UIView()
    private let contentContainerView = UIView()
    private let calendarContentView = UIView()
    private let reportContentView = ReportContentView()
    private var currentContentView: UIView?

    fileprivate let segmentedControl = UISegmentedControl(items: ["캘린더", "리포트"]).then {
        $0.selectedSegmentIndex = 0
        $0.selectedSegmentTintColor = .white
        $0.backgroundColor = .gray25
        $0.setTitleTextAttributes([
            .foregroundColor: UIColor.primary400,
            .font: LabelConfiguration.body14Medium.font
        ], for: .selected)
        $0.setTitleTextAttributes([
            .foregroundColor: UIColor.gray600,
            .font: LabelConfiguration.body14Medium.font
        ], for: .normal)
    }

    private let calendarCardView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray100.cgColor
    }

    private let calendarView = UICalendarView().then {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(
            from: calendar.dateComponents([.year, .month], from: calendar.date(byAdding: .year, value: -5, to: today) ?? today)
        ) ?? today
        let endBaseDate = calendar.date(byAdding: .year, value: 1, to: today) ?? today
        let endMonthStartDate = calendar.date(
            from: calendar.dateComponents([.year, .month], from: endBaseDate)
        ) ?? endBaseDate
        let endDate = calendar.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: endMonthStartDate
        ) ?? endBaseDate

        $0.calendar = Calendar(identifier: .gregorian)
        $0.locale = Locale(identifier: "ko_KR")
        $0.tintColor = .primary400
        $0.backgroundColor = .clear
        $0.availableDateRange = DateInterval(
            start: startDate,
            end: endDate
        )
        $0.visibleDateComponents = calendar.dateComponents([.year, .month], from: Date())
    }

    private let selectedDateLabel = UILabel(text: "5월 18일 월요일", config: .body16Medium)
    fileprivate let todayButtonContainer = UIControl()
    private let todayButton = UIButton(type: .system).then {
        $0.setTitle("오늘", for: .normal)
        $0.setTitleColor(.gray600, for: .normal)
        $0.titleLabel?.font = LabelConfiguration.body12Medium.font
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 16
        $0.isUserInteractionEnabled = false
    }

    fileprivate let weightCard = CalendarInfoCardView(title: "몸무게", value: "입력 필요", unit: "kg")
    fileprivate let conditionCard = CalendarInfoCardView(
        title: "컨디션",
        value: "입력 필요",
        unit: nil,
        valueImage: nil
    )
    fileprivate let weightCardTapArea = UIControl()
    fileprivate let conditionCardTapArea = UIControl()

    private let exerciseTitleLabel = UILabel(text: "운동", config: .body16Medium)

    private lazy var exerciseCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeExerciseCollectionViewLayout()).then {
        $0.backgroundColor = .gray25
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.showsVerticalScrollIndicator = false
        $0.isScrollEnabled = false
        $0.register(CalendarExerciseCell.self, forCellWithReuseIdentifier: CalendarExerciseCell.reuseIdentifier)
        $0.register(
            CalendarExerciseFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: CalendarExerciseFooterView.reuseIdentifier
        )
    }

    private let calendar = Calendar(identifier: .gregorian)
    fileprivate let dateSelectedRelay = PublishRelay<Date>()
    private var isUpdatingSelectedDate = false
    private var exerciseCollectionViewHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
        setCalendarSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarView {
    func updateWeight(_ weight: CalendarReactor.WeightValue?) {
        weightCard.updateValue(weight?.displayText ?? "입력 필요")
        weightCard.updateUnitHidden(weight == nil)
    }

    func updateCondition(_ condition: CalendarReactor.ConditionValue?) {
        conditionCard.updateValue(condition?.displayText ?? "입력 필요")
        conditionCard.updateValueImage(condition?.image)
    }

    func setExerciseCollectionViewDataSource(_ dataSource: UICollectionViewDataSource) {
        exerciseCollectionView.dataSource = dataSource
    }

    func reloadExerciseItems(count: Int) {
        exerciseCollectionView.reloadData()
        exerciseCollectionViewHeightConstraint?.update(offset: CGFloat(count) * 60 + 88)
    }

    func updateSelectedDate(_ date: Date, text: String) {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        calendarView.setVisibleDateComponents(dateComponents, animated: true)

        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            isUpdatingSelectedDate = true
            selection.setSelected(dateComponents, animated: true)
            isUpdatingSelectedDate = false
        }

        selectedDateLabel.text = text
    }

    func updateContentMode(_ mode: ContentMode) {
        switch mode {
        case .calendar:
            replaceContentView(with: calendarContentView)
        case .report:
            replaceContentView(with: reportContentView)
        }
    }
}

private extension CalendarView {
    func setStyle() {
        backgroundColor = .white
        scrollView.backgroundColor = .white
    }

    func setLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            segmentedControl,
            contentContainerView
        ].forEach(contentView.addSubview)

        [
            calendarCardView,
            selectedDateLabel,
            weightCard,
            conditionCard,
            weightCardTapArea,
            conditionCardTapArea,
            exerciseTitleLabel,
            exerciseCollectionView
        ].forEach(calendarContentView.addSubview)

        calendarCardView.addSubview(calendarView)
        calendarCardView.addSubview(todayButtonContainer)
        todayButtonContainer.addSubview(todayButton)

        scrollView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }

        contentContainerView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        replaceContentView(with: calendarContentView)

        calendarCardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(372)
        }

        calendarView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        selectedDateLabel.snp.makeConstraints {
            $0.top.equalTo(calendarCardView.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        todayButtonContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().inset(2)
            $0.width.equalTo(80)
            $0.height.equalTo(50)
        }

        todayButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(58)
            $0.height.equalTo(35)
        }

        weightCard.snp.makeConstraints {
            $0.top.equalTo(selectedDateLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(calendarContentView.snp.centerX).offset(-8)
            $0.height.equalTo(76)
        }

        conditionCard.snp.makeConstraints {
            $0.top.equalTo(weightCard)
            $0.leading.equalTo(calendarContentView.snp.centerX).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(weightCard)
        }

        weightCardTapArea.snp.makeConstraints {
            $0.edges.equalTo(weightCard)
        }

        conditionCardTapArea.snp.makeConstraints {
            $0.edges.equalTo(conditionCard)
        }

        exerciseTitleLabel.snp.makeConstraints {
            $0.top.equalTo(weightCard.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        exerciseCollectionView.snp.makeConstraints {
            $0.top.equalTo(exerciseTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            exerciseCollectionViewHeightConstraint = $0.height.equalTo(24).constraint
            $0.bottom.equalToSuperview()
        }

    }

    func replaceContentView(with nextContentView: UIView) {
        guard currentContentView !== nextContentView else { return }

        currentContentView?.removeFromSuperview()
        contentContainerView.addSubview(nextContentView)
        nextContentView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        currentContentView = nextContentView
    }

    func setCalendarSelection() {
        let selection = UICalendarSelectionSingleDate(delegate: self)
        let selectedDate = calendar.dateComponents([.year, .month, .day], from: Date())
        selection.setSelected(selectedDate, animated: false)
        calendarView.selectionBehavior = selection
    }

    func makeExerciseCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(60)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(60)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(64)
                ),
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
        ]
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension CalendarView: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard !isUpdatingSelectedDate else { return }
        guard let dateComponents,
              let date = dateComponents.date
        else { return }

        dateSelectedRelay.accept(date)
    }
}

extension Reactive where Base == CalendarView {
    var todayButtonTap: ControlEvent<Void> {
        base.todayButtonContainer.rx.controlEvent(.touchUpInside)
    }

    var dateSelected: ControlEvent<Date> {
        ControlEvent(events: base.dateSelectedRelay)
    }

    var weightCardTap: ControlEvent<Void> {
        base.weightCardTapArea.rx.controlEvent(.touchUpInside)
    }

    var conditionCardTap: ControlEvent<Void> {
        base.conditionCardTapArea.rx.controlEvent(.touchUpInside)
    }

    var selectedSegmentIndex: ControlProperty<Int> {
        base.segmentedControl.rx.selectedSegmentIndex
    }
}
