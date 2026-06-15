//
//  HomeLocationView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/12/26.
//

import UIKit
import Then
import SnapKit
import RxCocoa
import RxSwift

final class LocationView: UIView {
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .arrowLeft, rightButtonImage: .edit)
    let searchBar = SearchBar(placeholder: "주소로 검색하기").then {
        $0.isTextInputEnabled = false
    }
    let currentLocationButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "현재 위치로 지정"
    }
    
    fileprivate let searchBarTapGesture = UITapGestureRecognizer()
    
    // collectionView
    private(set) lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    private(set) lazy var dataSource = makeDiffableDataSource(collectionView)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        searchBar.addGestureRecognizer(searchBarTapGesture)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LocationView {
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
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}

//MARK: CollectionView DataSource
extension LocationView {
    private func makeDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, Location> {
        let listCellRegistration = UICollectionView.CellRegistration<LocationListCell, Location> { cell, indexPath, item in
            
            cell.configure(item)
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
extension LocationView {
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
                heightDimension: .absolute(81)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(81)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        
        return section
    }
    
}

extension Reactive where Base: LocationView {
    var backButtonTap: ControlEvent<Void> {
        base.titleView.rx.leftButtonTap
    }
    
    var editButtonTap: ControlEvent<Void> {
        base.titleView.rx.rightButtonTap
    }
    
    var currentLocationButtonTap: ControlEvent<Void> {
        base.currentLocationButton.rx.tap
    }
    
    var searchBarTap: ControlEvent<Void> {
        let source = base.searchBarTapGesture.rx.event.map { _ in }
        return ControlEvent(events: source)
    }
    
    var listCellSelected: Observable<Location> {
        base.collectionView.rx.itemSelected
            .compactMap { indexPath in
                base.dataSource.itemIdentifier(for: indexPath)
            }
            .asObservable()
    }
}

nonisolated
struct Location: Hashable {
    let icon: UIImage
    let name: String
    let address: String
    let isSelected: Bool
    let latitude: Double
    let longitude: Double
}
