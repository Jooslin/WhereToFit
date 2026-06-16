//
//  ExerciseNameSelectionTableHandler.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/16/26.
//

import SnapKit
import UIKit

final class ExerciseNameSelectionTableHandler: NSObject {
    var onCategorySelected: ((SportsCategory) -> Void)?
    var onSportSelected: ((String) -> Void)?

    private weak var searchResultTableView: UITableView?
    private weak var categoryTableView: UITableView?
    private weak var sportTableView: UITableView?

    private var categories: [SportsCategory] = []
    private var sports: [String] = []
    private var searchResults: [String] = []
    private var selectedCategory: SportsCategory?
    private var selectedSport: String?

    func configure(
        searchResultTableView: UITableView,
        categoryTableView: UITableView,
        sportTableView: UITableView
    ) {
        self.searchResultTableView = searchResultTableView
        self.categoryTableView = categoryTableView
        self.sportTableView = sportTableView

        searchResultTableView.register(
            ExerciseSportCell.self,
            forCellReuseIdentifier: ExerciseSportCell.reuseIdentifier
        )
        categoryTableView.register(
            ExerciseCategoryCell.self,
            forCellReuseIdentifier: ExerciseCategoryCell.reuseIdentifier
        )
        sportTableView.register(
            ExerciseSportCell.self,
            forCellReuseIdentifier: ExerciseSportCell.reuseIdentifier
        )

        searchResultTableView.dataSource = self
        searchResultTableView.delegate = self
        categoryTableView.dataSource = self
        categoryTableView.delegate = self
        sportTableView.dataSource = self
        sportTableView.delegate = self
    }

    func update(
        categories: [SportsCategory],
        selectedCategory: SportsCategory?,
        sports: [String],
        searchResults: [String],
        selectedSport: String?
    ) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.sports = sports
        self.searchResults = searchResults
        self.selectedSport = selectedSport
    }

    func reloadTables() {
        searchResultTableView?.reloadData()
        categoryTableView?.reloadData()
        sportTableView?.reloadData()
    }
}

extension ExerciseNameSelectionTableHandler: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === searchResultTableView {
            return searchResults.count
        }

        if tableView === categoryTableView {
            return categories.count
        }

        return sports.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === searchResultTableView {
            return sportCell(
                tableView,
                for: indexPath,
                title: searchResults[indexPath.row]
            )
        }

        if tableView === categoryTableView {
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

        return sportCell(
            tableView,
            for: indexPath,
            title: sports[indexPath.row]
        )
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if tableView === categoryTableView {
            onCategorySelected?(categories[indexPath.row])
        } else if tableView === searchResultTableView {
            onSportSelected?(searchResults[indexPath.row])
        } else {
            onSportSelected?(sports[indexPath.row])
        }
    }
}

private extension ExerciseNameSelectionTableHandler {
    func sportCell(
        _ tableView: UITableView,
        for indexPath: IndexPath,
        title: String
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseSportCell.reuseIdentifier,
            for: indexPath
        ) as? ExerciseSportCell else {
            return UITableViewCell()
        }

        cell.configure(title: title, isSelected: title == selectedSport)
        return cell
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
