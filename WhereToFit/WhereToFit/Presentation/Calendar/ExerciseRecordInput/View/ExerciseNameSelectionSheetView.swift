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

    let applyButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "적용"
    }

    private let tableHandler = ExerciseNameSelectionTableHandler()
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
        $0.backgroundColor = .gray50
    }

    private let searchResultTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = true
        $0.backgroundColor = .white
        $0.rowHeight = 44
    }

    private let categoryTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = true
        $0.backgroundColor = .white
        $0.rowHeight = 44
    }

    private let sportTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = true
        $0.backgroundColor = .white
        $0.rowHeight = 44
    }

    private lazy var listContainerView = UIView().then {
        $0.addSubview(categoryTableView)
        $0.addSubview(sportTableView)
    }

    private lazy var buttonStackView = UIStackView(arrangedSubviews: [
        applyButton
    ]).then {
        $0.axis = .horizontal
        $0.distribution = .fill
    }

    private var searchResultHeightConstraint: Constraint?

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
        selectedCategory: SportsCategory?,
        sports: [String],
        searchResults: [String],
        selectedSport: String?,
        searchText: String
    ) {
        let isSearchActive = !searchText.isEmpty

        if searchBar.text != searchText {
            searchBar.text = searchText
        }

        tableHandler.update(
            categories: categories,
            selectedCategory: selectedCategory,
            sports: sports,
            searchResults: searchResults,
            selectedSport: selectedSport
        )

        searchResultHeightConstraint?.update(offset: isSearchActive ? 132 : 0)
        searchResultTableView.isHidden = !isSearchActive
        tableHandler.reloadTables()
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
            searchResultTableView,
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
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.height.equalTo(48)
        }

        searchResultTableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            searchResultHeightConstraint = $0.height.equalTo(0).constraint
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(searchResultTableView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.height.equalTo(1)
        }

        listContainerView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.height.equalTo(320)
        }

        categoryTableView.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview()
            $0.trailing.equalTo(listContainerView.snp.centerX).offset(-12)
        }

        sportTableView.snp.makeConstraints {
            $0.leading.equalTo(listContainerView.snp.centerX).offset(12)
            $0.trailing.verticalEdges.equalToSuperview()
            $0.width.equalTo(categoryTableView)
        }

        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(listContainerView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setTables() {
        tableHandler.configure(
            searchResultTableView: searchResultTableView,
            categoryTableView: categoryTableView,
            sportTableView: sportTableView
        )
        tableHandler.onCategorySelected = { [weak self] category in
            self?.categorySelectedRelay.accept(category)
        }
        tableHandler.onSportSelected = { [weak self] sport in
            self?.sportSelectedRelay.accept(sport)
        }
        searchResultTableView.isHidden = true
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
