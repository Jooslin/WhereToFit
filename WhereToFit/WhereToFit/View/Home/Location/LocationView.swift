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
    
    let currentLocationButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "현재 위치로 지정하기"
    }
    
    // collectionView
    private(set) lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    private(set) lazy var dataSource = makeDiffableDataSource(collectionView)
    
    // Reactive
    fileprivate let addButtonTap = PublishRelay<Void>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
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
        addSubview(collectionView)
        addSubview(currentLocationButton)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
       
        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(currentLocationButton.snp.top).inset(12)
        }
        
        currentLocationButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
    }
}

//MARK: CollectionView DataSource
extension LocationView {
    private func makeDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Section, Item> {
        let listCellRegistration = UICollectionView.CellRegistration<LocationListCell, Item> { cell, indexPath, item in
            
            switch item {
            case .location(let location):
                cell.configure(location)
            case .button:
                break
            }
        }
        
        let buttonCellRegistration = UICollectionView.CellRegistration<LocationButtonCell, Item> { [weak self] cell, indexPath, item in
            guard let self else { return }
            cell.rx.addButtonTap
                .bind(to: self.addButtonTap)
                .disposed(by: cell.disposeBag)
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                fatalError("LocationCollectionView: 유효하지 않은 섹션입니다.")
            }
            
            return switch section {
            case .location:
                collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
            case .button:
                collectionView.dequeueConfiguredReusableCell(using: buttonCellRegistration, for: indexPath, item: item)
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(with data: [Section: [Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.location, .button])
        snapshot.appendItems(data[.location] ?? [], toSection: .location)
        snapshot.appendItems(data[.button] ?? [], toSection: .button)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: CollectionView Layout
extension LocationView {
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            
            switch section {
            case .location:
                return self?.listSectionLayout()
            case .button:
                return self?.listSectionLayout(height: 40)
            }
        }, configuration: configuration)
    }
    
    private func listSectionLayout(height: CGFloat  = 81) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        
        return section
    }
    
}

extension LocationView {
    nonisolated
    enum Section: Int {
        case location = 0
        case button
    }
    
    nonisolated
    enum Item: Hashable {
        case location(UserLocation)
        case button
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
    
    var listCellSelected: Observable<UserLocation> {
        base.collectionView.rx.itemSelected
            .compactMap { indexPath in
                guard case LocationView.Item.location(let location)? = base.dataSource.itemIdentifier(for: indexPath) else {
                    return nil
                }
                
                return location
            }
            .asObservable()
    }
    
    var locationAddButtonTap: PublishRelay<Void> {
        base.addButtonTap
    }
}
