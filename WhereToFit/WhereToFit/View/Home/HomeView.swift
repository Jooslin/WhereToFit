//
//  HomeView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit
import SnapKit
import Then

final class HomeView: UIView {
    let titleView = TitleView(rightButtonImage: .alarm)
    private lazy var collectionView = HomeCollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
    private lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    init() {
        super.init(frame: .zero)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLayout() {
        addSubview(titleView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
    }
}

//MARK: CollectionView - Layout
extension HomeView {
    private func makeCompositionalLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(25)
                ),
                elementKind: "headerKind",
                alignment: .top
            )
            
            let weatherBackgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "weatherBackground")
            
            switch section {
            case .weather:
                let section = self?.weatherItemSectionLayout()
                return section
            }
            
        }, configuration: configuration)
        
        layout.register(CalendarBackgroundView.self, forDecorationViewOfKind: "weatherBackground")
        return layout
    }
    
    private func weatherItemSectionLayout(height: CGFloat = 48) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            ))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private func horizontalGroupItemSectionLayout(height: CGFloat) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            ))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}
