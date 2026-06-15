//
//  ExerciseNameSelectionSheetView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ExerciseNameSelectionSheetView: UIView {
    let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .gray600
    }

    let resetButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "초기화"
    }

    let applyButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "적용"
    }

    fileprivate let categorySelectedRelay = PublishRelay<SportsCategory>()
    fileprivate let sportSelectedRelay = PublishRelay<String>()

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }

    private let sheetView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray200
        $0.layer.cornerRadius = 2
    }

    private let titleLabel = UILabel(text: "운동 종목", config: .body14Medium, color: .gray700)
    fileprivate let searchBar = SearchBar(placeholder: "하고 싶은 운동 종목 입력")
    private let dividerView = UIView().then {
        $0.backgroundColor = .gray100
    }

    private let categoryTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .white
        $0.rowHeight = 44
        $0.register(ExerciseCategoryCell.self, forCellReuseIdentifier: ExerciseCategoryCell.reuseIdentifier)
    }

    private let verticalDividerView = UIView().then {
        $0.backgroundColor = .gray200
    }

    private let sportTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .white
        $0.rowHeight = 44
        $0.register(ExerciseSportCell.self, forCellReuseIdentifier: ExerciseSportCell.reuseIdentifier)
    }

    private lazy var listContainerView = UIView().then {
        $0.addSubview(categoryTableView)
        $0.addSubview(verticalDividerView)
        $0.addSubview(sportTableView)
    }

    private lazy var buttonStackView = UIStackView(arrangedSubviews: [
        resetButton,
        applyButton
    ]).then {
        $0.axis = .horizontal
        $0.spacing = 20
        $0.distribution = .fillEqually
    }

    private var categories: [SportsCategory] = []
    private var sports: [String] = []
    private var selectedCategory: SportsCategory?
    private var selectedSport: String?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
        setTables()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExerciseNameSelectionSheetView {
    func update(
        categories: [SportsCategory],
        selectedCategory: SportsCategory,
        sports: [String],
        selectedSport: String?,
        searchText: String
    ) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.sports = sports
        self.selectedSport = selectedSport

        if searchBar.text != searchText {
            searchBar.text = searchText
        }

        categoryTableView.reloadData()
        sportTableView.reloadData()
    }
}

private extension ExerciseNameSelectionSheetView {
    func setStyle() {
        backgroundColor = .clear
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            handleView,
            titleLabel,
            closeButton,
            searchBar,
            dividerView,
            listContainerView,
            buttonStackView
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(40)
            $0.leading.equalToSuperview().offset(16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        listContainerView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(320)
        }

        categoryTableView.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview()
            $0.trailing.equalTo(verticalDividerView.snp.leading).offset(-12)
        }

        verticalDividerView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.verticalEdges.equalToSuperview()
            $0.width.equalTo(1)
        }

        sportTableView.snp.makeConstraints {
            $0.leading.equalTo(verticalDividerView.snp.trailing).offset(12)
            $0.trailing.verticalEdges.equalToSuperview()
            $0.width.equalTo(categoryTableView)
        }

        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(listContainerView.snp.bottom).offset(28)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setTables() {
        categoryTableView.dataSource = self
        categoryTableView.delegate = self
        sportTableView.dataSource = self
        sportTableView.delegate = self
    }
}

extension ExerciseNameSelectionSheetView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == categoryTableView ? categories.count : sports.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == categoryTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ExerciseCategoryCell.reuseIdentifier,
                for: indexPath
            ) as? ExerciseCategoryCell else {
                return UITableViewCell()
            }

            let category = categories[indexPath.row]
            cell.configure(title: category.rawValue, isSelected: category == selectedCategory)
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseSportCell.reuseIdentifier,
            for: indexPath
        ) as? ExerciseSportCell else {
            return UITableViewCell()
        }

        let sport = sports[indexPath.row]
        cell.configure(title: sport, isSelected: sport == selectedSport)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if tableView == categoryTableView {
            categorySelectedRelay.accept(categories[indexPath.row])
        } else {
            sportSelectedRelay.accept(sports[indexPath.row])
        }
    }
}

extension Reactive where Base == ExerciseNameSelectionSheetView {
    var searchText: ControlProperty<String?> {
        base.searchBar.rx.text
    }

    var categorySelected: ControlEvent<SportsCategory> {
        ControlEvent(events: base.categorySelectedRelay)
    }

    var sportSelected: ControlEvent<String> {
        ControlEvent(events: base.sportSelectedRelay)
    }
}

private final class ExerciseCategoryCell: UITableViewCell {
    static let reuseIdentifier = "ExerciseCategoryCell"

    private let titleLabel = UILabel(config: .body14Medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .gray900 : .gray500
        contentView.backgroundColor = isSelected ? .gray50 : .white
    }
}

private extension ExerciseCategoryCell {
    func setStyle() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.layer.cornerRadius = 8
    }

    func setLayout() {
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
    }
}

private final class ExerciseSportCell: UITableViewCell {
    static let reuseIdentifier = "ExerciseSportCell"

    private let checkLabel = UILabel(text: "✓", config: .body14Medium, color: .primary400)
    private let titleLabel = UILabel(config: .body14Medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .gray900 : .gray500
        checkLabel.isHidden = !isSelected
    }
}

private extension ExerciseSportCell {
    func setStyle() {
        selectionStyle = .none
        backgroundColor = .white
    }

    func setLayout() {
        contentView.addSubview(checkLabel)
        contentView.addSubview(titleLabel)

        checkLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(checkLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().inset(8)
        }
    }
}
