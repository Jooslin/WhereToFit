//
//  FavoriteProgramsView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import SnapKit
import Then
import UIKit

final class FavoriteProgramsView: UIView {
    let titleView = TitleView(text: "찜한 시설 및 프로그램", leftButtonImage: UIImage(resource: .arrowLeft))
    let segmentedControl = UISegmentedControl(items: ["찜한 시설", "찜한 프로그램"])

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.dataSource = self
        $0.register(FavoriteListCell.self, forCellWithReuseIdentifier: FavoriteListCell.reuseIdentifier)
    }
    private var items: [FavoriteProgramsReactor.FavoriteItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FavoriteProgramsView {
    func updateSelectedTab(_ tab: FavoriteProgramsReactor.FavoriteTab) {
        segmentedControl.selectedSegmentIndex = tab.segmentIndex
    }

    func updateItems(_ items: [FavoriteProgramsReactor.FavoriteItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

private extension FavoriteProgramsView {
    func setStyle() {
        backgroundColor = .white
        segmentedControl.selectedSegmentIndex = FavoriteProgramsReactor.FavoriteTab.facility.segmentIndex
        segmentedControl.selectedSegmentTintColor = .white
        segmentedControl.backgroundColor = .gray50
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.gray600,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ],
            for: .normal
        )
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.primary400,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ],
            for: .selected
        )
    }

    func setLayout() {
        [
            titleView,
            segmentedControl,
            collectionView
        ].forEach(addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
    }

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(94)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(94)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12

        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension FavoriteProgramsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FavoriteListCell.reuseIdentifier,
            for: indexPath
        ) as? FavoriteListCell else {
            return UICollectionViewCell()
        }

        cell.configure(item: items[indexPath.item])
        return cell
    }
}
