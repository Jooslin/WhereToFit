//
//  HomeView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxSwift

final class HomeView: UIView {
    private let titleView = TitleView(rightButtonImage: .alarm)
    private lazy var collectionView = HomeCollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
    private lazy var dataSource = makeCollectionViewDiffableDataSource(collectionView)
    
    // Reactive
    fileprivate let registerButtonTap = PublishRelay<Void>()
    fileprivate let programButtonTap = PublishRelay<Void>()
//    fileprivate let surveyButtonTap = PublishRelay<Void>()
    
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

//MARK: CollectionView - Datasource
extension HomeView {
    private func makeCollectionViewDiffableDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<HomeCollectionView.Section, HomeCollectionView.Item> {
        let headerViewRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>(elementKind: "headerKind") { [weak self] supplementaryView, elementKind, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            
            switch section {
            case .recommend:
                supplementaryView.titleLabel.text = "오늘의 맞춤 운동 AI 추천"
            case .program:
                supplementaryView.titleLabel.text = "주변 프로그램"
            default:
                break
            }
        }
        
        
        let weatherCellRegistration = UICollectionView.CellRegistration<HomeWeatherCell, HomeCollectionView.Item> { [weak self] cell,indexPath,item in
            guard let self else { return }
            
            cell.rx.registerButtonTap
                .bind(to: self.registerButtonTap)
                .disposed(by: cell.disposeBag)
            
            cell.rx.recordButtonTap
                .bind(to: self.registerButtonTap)
                .disposed(by: cell.disposeBag)
        }
        
        let recommendCellRegistration = UICollectionView.CellRegistration<HomeRecommendCell, HomeCollectionView.Item> { cell, indexPath, item in
            cell.configure(image: .alarm, text: "더미")
        }
        
        let onboardingCellRegistration = UICollectionView.CellRegistration<HomeOnboardingCell, HomeCollectionView.Item> { [weak self] cell,indexPath,item in
            guard let self else { return }
            
//            cell.rx.surveyButtonTap
//                .bind(to: self.surveyButtonTap)
//                .disposed(by: cell.disposeBag)
        }
        
        let programCellRegistration = UICollectionView.CellRegistration<HomeProgramCell, HomeCollectionView.Item> { cell, indexPath, item in
            cell.configure(image: .alarm, text: "더미")
        }
        
        let dataSource = UICollectionViewDiffableDataSource<HomeCollectionView.Section, HomeCollectionView.Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            
            guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                fatalError("CalendarCollectionView: 유효하지 않은 섹션입니다.")
            }
            
            return switch section {
            case .weather:
                collectionView.dequeueConfiguredReusableCell(using: weatherCellRegistration, for: indexPath, item: item)
            case .recommend:
                collectionView.dequeueConfiguredReusableCell(using: recommendCellRegistration, for: indexPath, item: item)
            case .onboarding:
                collectionView.dequeueConfiguredReusableCell(using: onboardingCellRegistration, for: indexPath, item: item)
            case .program:
                collectionView.dequeueConfiguredReusableCell(using: programCellRegistration, for: indexPath, item: item)
            }
        }
        
        dataSource.supplementaryViewProvider = {
            switch $1 {
            case "headerKind":
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerViewRegistration, for: $2)
            default:
                return UICollectionReusableView()
            }
        }
        
        return dataSource
    }
    
    func setSnapshot(_ data: [HomeCollectionView.Section: [HomeCollectionView.Item]]) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeCollectionView.Section, HomeCollectionView.Item>()
        
        for target in data.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if !target.value.isEmpty {
                snapshot.appendSections([target.key])
                snapshot.appendItems(target.value, toSection: target.key)
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
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
                let section = self?.singleItemSectionLayout(height: 324)
                section?.decorationItems = [weatherBackgroundItem]
                return section
                
            case .recommend:
                let section = self?.horizontalGroupItemSectionLayout(height: 130)
                section?.boundarySupplementaryItems = [headerItem]
                section?.contentInsets = .init(top: 12, leading: 0, bottom: 0, trailing: 0)
                return section
                
            case .onboarding:
                let section = self?.singleItemSectionLayout(height: 68)
                return section
                
            case .program:
                let section = self?.horizontalGroupItemSectionLayout(height: 202)
                section?.boundarySupplementaryItems = [headerItem]
                section?.contentInsets = .init(top: 12, leading: 0, bottom: 0, trailing: 0)
                return section
            }
            
        }, configuration: configuration)
        
        layout.register(HomeBackgroundView.self, forDecorationViewOfKind: "weatherBackground")
        return layout
    }
    
    // single item section - weather, onboarding
    private func singleItemSectionLayout(height: CGFloat) -> NSCollectionLayoutSection {
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
    
    // horizontal multiple item section - recommend, program
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
        
        group.interItemSpacing = .fixed(12)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}

extension Reactive where Base: HomeView {
    var registerButtonTap: PublishRelay<Void> {
        base.rx.registerButtonTap
    }
    
    var recordButtonTap: PublishRelay<Void> {
        base.rx.registerButtonTap
    }
    
//    var surveyButtonTap: PublishRelay<Void> {
//        base.rx.surveyButtonTap
//    }
}
