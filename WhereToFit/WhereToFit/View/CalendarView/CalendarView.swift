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
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    private let contentView = UIView()

    private let segmentedControl = UISegmentedControl(items: ["캘린더", "리포트"]).then {
        $0.selectedSegmentIndex = 0
        $0.selectedSegmentTintColor = .white
        $0.backgroundColor = .gray50
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
        $0.calendar = Calendar(identifier: .gregorian)
        $0.locale = Locale(identifier: "ko_KR")
        $0.tintColor = .primary400
        $0.backgroundColor = .clear
        $0.availableDateRange = DateInterval(
            start: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 1, day: 1).date ?? Date(),
            end: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 12, day: 31).date ?? Date()
        )
        $0.visibleDateComponents = DateComponents(year: 2026, month: 5)
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

    fileprivate let weightCard = CalendarInfoCardView(title: "몸무게", value: "54.2", unit: "kg")
    fileprivate let conditionCard = CalendarInfoCardView(title: "컨디션", value: "최악", unit: nil)

    private let exerciseTitleLabel = UILabel(text: "운동", config: .body16Medium)
    fileprivate let exerciseAddButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .gray700
    }

    private lazy var exerciseCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeExerciseCollectionViewLayout()).then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.showsVerticalScrollIndicator = false
        $0.isScrollEnabled = false
        $0.dataSource = self
        $0.register(CalendarExerciseCell.self, forCellWithReuseIdentifier: CalendarExerciseCell.reuseIdentifier)
    }

    private let calendar = Calendar(identifier: .gregorian)
    private var exerciseItems: [CalendarReactor.ExerciseItem] = []
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
    func updateWeight(_ weight: CalendarReactor.WeightValue) {
        weightCard.updateValue(weight.displayText)
    }

    func updateCondition(_ condition: CalendarReactor.ConditionValue) {
        conditionCard.updateValue(condition.displayText)
    }

    func updateExerciseItems(_ items: [CalendarReactor.ExerciseItem]) {
        exerciseItems = items
        exerciseCollectionView.reloadData()
        exerciseCollectionViewHeightConstraint?.update(offset: CGFloat(items.count) * 60 + 24)
    }

    func moveToToday() {
        let today = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        calendarView.setVisibleDateComponents(todayComponents, animated: true)

        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            selection.setSelected(todayComponents, animated: true)
        }

        updateSelectedDateLabel(date: today)
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
            calendarCardView,
            selectedDateLabel,
            weightCard,
            conditionCard,
            exerciseTitleLabel,
            exerciseAddButton,
            exerciseCollectionView
        ].forEach(contentView.addSubview)

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

        calendarCardView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(16)
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
            $0.trailing.equalTo(contentView.snp.centerX).offset(-8)
            $0.height.equalTo(76)
        }

        conditionCard.snp.makeConstraints {
            $0.top.equalTo(weightCard)
            $0.leading.equalTo(contentView.snp.centerX).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(weightCard)
        }

        exerciseTitleLabel.snp.makeConstraints {
            $0.top.equalTo(weightCard.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(exerciseAddButton)
            $0.trailing.lessThanOrEqualTo(exerciseAddButton.snp.leading).offset(-12)
        }

        exerciseAddButton.snp.makeConstraints {
            $0.top.equalTo(weightCard.snp.bottom).offset(10)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        exerciseCollectionView.snp.makeConstraints {
            $0.top.equalTo(exerciseTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            exerciseCollectionViewHeightConstraint = $0.height.equalTo(24).constraint
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    func setCalendarSelection() {
        let selection = UICalendarSelectionSingleDate(delegate: self)
        let selectedDate = DateComponents(calendar: calendar, year: 2026, month: 5, day: 18)
        selection.setSelected(selectedDate, animated: false)
        calendarView.selectionBehavior = selection
    }

    func updateSelectedDateLabel(date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        selectedDateLabel.text = formatter.string(from: date)
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
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension CalendarView: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents,
              let date = dateComponents.date
        else { return }

        updateSelectedDateLabel(date: date)
    }
}

extension CalendarView: UICollectionViewDataSource {
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

extension Reactive where Base == CalendarView {
    var todayButtonTap: ControlEvent<Void> {
        base.todayButtonContainer.rx.controlEvent(.touchUpInside)
    }

    var weightCardTap: ControlEvent<Void> {
        base.weightCard.rx.controlEvent(.touchUpInside)
    }

    var conditionCardTap: ControlEvent<Void> {
        base.conditionCard.rx.controlEvent(.touchUpInside)
    }

    var exerciseAddButtonTap: ControlEvent<Void> {
        base.exerciseAddButton.rx.tap
    }
}
