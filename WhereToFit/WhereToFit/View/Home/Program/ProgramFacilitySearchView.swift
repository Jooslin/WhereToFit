//
//  ProgramFacilitySearchView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import Then
import SnapKit
import RxCocoa
import RxSwift

final class ProgramFacilitySearchView: UIView {
    let titleView = TitleView(text: "시설 검색", leftButtonImage: .arrowLeft)
    private(set) lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    private(set) lazy var dataSource = makeDiffableDataSource(collectionView)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProgramFacilitySearchView {
    private func setLayout() {
        addSubview(titleView)
        addSubview(collectionView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}

//MARK: CollectionView DataSource
extension ProgramFacilitySearchView {
    private func makeDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, Item> {
        let listCellRegistration = UICollectionView.CellRegistration<ProgramFacilityListCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            cell.configure(with: item)
            
            let itemNumber = self.dataSource.snapshot().numberOfItems(inSection: 0)
            let isLast = indexPath.item == itemNumber - 1
            cell.hideSeparateBar(isLast)
        
        }

        let dataSource = UICollectionViewDiffableDataSource<Int, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
        }
        
        return dataSource
    }
    
    func setSnapshot(with data: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems(data, toSection: 0)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: CollectionView Layout
extension ProgramFacilitySearchView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            self?.listSectionLayout()
        }, configuration: configuration)
    }
    
    private func listSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(77)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(77)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        
        return section
    }
}

//MARK: CollectionView Item
extension ProgramFacilitySearchView {
    nonisolated
    struct Item: Hashable {
        let id: UUID
        let name: String
        let address: String
        let distance: Double
    }
}

//MARK: Reactive
extension Reactive where Base: ProgramFacilitySearchView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.leftButtonTap
    }
    
    var listCellSelected: Observable<ProgramFacilitySearchView.Item> {
        base.collectionView.rx.itemSelected
            .compactMap { indexPath in
                base.dataSource.itemIdentifier(for: indexPath)
            }
            .asObservable()
    }
}
