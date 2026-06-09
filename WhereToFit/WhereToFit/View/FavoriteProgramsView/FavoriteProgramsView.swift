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
    struct FavoriteItem {
        let name: String
        let schedule: String
        let distance: String
        let price: String
    }

    let titleView = TitleView(text: "찜한 시설 및 프로그램", leftButtonImage: UIImage(resource: .arrowLeft))

    private let segmentedControl = FavoriteSegmentedControl()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.dataSource = self
        $0.register(FavoriteProgramCell.self, forCellWithReuseIdentifier: FavoriteProgramCell.reuseIdentifier)
    }

    private let items: [FavoriteItem] = [
        FavoriteItem(name: "올림픽수영장", schedule: "월-금 06:00-23:00", distance: "거리 1.0km", price: "원~"),
        FavoriteItem(name: "곰두리체육문화회관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
        FavoriteItem(name: "송파여성체육문화회관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
        FavoriteItem(name: "송파배드민턴체육관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~")
    ]

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

private extension FavoriteProgramsView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            segmentedControl,
            collectionView
        ].forEach(addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(11)
            $0.horizontalEdges.equalToSuperview()
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(31)
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
            withReuseIdentifier: FavoriteProgramCell.reuseIdentifier,
            for: indexPath
        ) as? FavoriteProgramCell else {
            return UICollectionViewCell()
        }

        cell.configure(item: items[indexPath.item])
        return cell
    }
}

private final class FavoriteSegmentedControl: UIView {
    private let selectedBackgroundView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 24
    }
    private let facilityLabel = UILabel(text: "찜한 시설", config: .body14Medium, color: .primary500).then {
        $0.textAlignment = .center
    }
    private let programLabel = UILabel(text: "찜한 프로그램", config: .body14Medium, color: .gray700).then {
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension FavoriteSegmentedControl {
    func setLayout() {
        backgroundColor = UIColor(red: 0.979, green: 0.98, blue: 0.981, alpha: 1)
        layer.cornerRadius = 25
        clipsToBounds = true

        [
            selectedBackgroundView,
            facilityLabel,
            programLabel
        ].forEach(addSubview)

        selectedBackgroundView.snp.makeConstraints {
            $0.verticalEdges.leading.equalToSuperview().inset(3)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-3)
        }

        facilityLabel.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.5)
        }

        programLabel.snp.makeConstraints {
            $0.trailing.verticalEdges.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.5)
        }
    }
}


