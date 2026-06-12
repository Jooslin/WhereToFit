//
//  HomeLocationView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/12/26.
//

import UIKit
import Then
import SnapKit

final class HomeLocationView: UIView {
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .arrowLeft, rightButtonImage: .edit)
    let searchBar = SearchBar(placeholder: "주소로 검색하기")
    let currentLocationButton = DesignButton(config: .largeBorderBlue)
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

extension HomeLocationView {
    private func setLayout() {
        addSubview(titleView)
        addSubview(searchBar)
        addSubview(currentLocationButton)
        addSubview(collectionView)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        currentLocationButton.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(currentLocationButton.snp.bottom).offset(12)
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}

//MARK: CollectionView DataSource
extension HomeLocationView {
    private func makeDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<OnboardingFacilityView.Section, OnboardingFacilityView.Item> {
        let listCellRegistration = UICollectionView.CellRegistration<OnboardingProgramListCell, OnboardingFacilityView.Item> { cell, indexPath, item in
            
            switch item {
            case .list(let program):
                cell.configure(program)
            case .button:
                break
            }
        }
        
        let addCellRegistration = UICollectionView.CellRegistration<OnboardingProgramAddCell, OnboardingFacilityView.Item> { cell, indexPath, item in
        }

        let dataSource = UICollectionViewDiffableDataSource<OnboardingFacilityView.Section, OnboardingFacilityView.Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                fatalError("OnboardingCollectionView: 유효하지 않은 섹션입니다.")
            }
            
            return switch section {
            case .list:
                collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
            case .button:
                collectionView.dequeueConfiguredReusableCell(using: addCellRegistration, for: indexPath, item: item)
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(with data: [OnboardingFacilityView.Section: [OnboardingFacilityView.Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<OnboardingFacilityView.Section, OnboardingFacilityView.Item>()
        snapshot.appendSections([.list, .button])
        
        let listItem = data[.list] ?? []
        let buttonItem = data[.button] ?? []
        snapshot.appendItems(listItem, toSection: .list)
        snapshot.appendItems(buttonItem, toSection: .button)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: CollectionView Layout
extension HomeLocationView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16
        configuration.contentInsetsReference = .layoutMargins
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            
            switch section {
            case .list:
                return self?.listSectionLayout()
            }
        }, configuration: configuration)
    }
    
    private func listSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(73)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(73)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        
        return section
    }
    
}
