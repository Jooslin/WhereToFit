//
//  HomeLocationEditView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/14/26.
//

import UIKit
import Then
import SnapKit
import RxCocoa
import RxSwift

final class HomeLocationEditView: UIView {
    let titleView = TitleView(text: "위치 편집", leftButtonImage: .arrowLeft)
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

extension HomeLocationEditView {
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
extension HomeLocationEditView {
    private func makeDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, Location> {
        let listCellRegistration = UICollectionView.CellRegistration<HomeLocationEditListCell, Location> { [weak self] cell, indexPath, item in
            guard let self else { return }
            cell.configure(item)
            
            let itemNumber = self.dataSource.snapshot().numberOfItems(inSection: 0)
            let isLast = indexPath.item == itemNumber - 1
            cell.hideSeparateBar(isLast)
        }

        let dataSource = UICollectionViewDiffableDataSource<Int, Location>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
        }
        
        return dataSource
    }
    
    func setSnapshot(with data: [Location]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Location>()
        snapshot.appendSections([0])
        snapshot.appendItems(data, toSection: 0)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: CollectionView Layout
extension HomeLocationEditView {
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
                heightDimension: .absolute(118)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(118)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        
        return section
    }
    
}

extension Reactive where Base: HomeLocationEditView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.leftButtonTap
    }
    
    var listCellSelected: Observable<Location> {
        base.collectionView.rx.itemSelected
            .compactMap { indexPath in
                base.dataSource.itemIdentifier(for: indexPath)
            }
            .asObservable()
    }
}
