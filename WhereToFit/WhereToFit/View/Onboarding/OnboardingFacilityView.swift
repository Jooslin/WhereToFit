//
//  OnboardingFacilityView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/6/26.
//

import UIKit
import SnapKit
import Then

final class OnboardingFacilityView: OnboardingBaseView {
    let negativeButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .label).then {
        $0.title = "아니요, 이제 이용해보려고 합니다"
        $0.isSelected = true
    }
    
    let positiveButton = OnboardingButton(config: .onboarding, selectedConfig: .selectedOnboarding, type: .label).then {
        $0.title = "네, 이용중입니다"
    }
    
    private(set) lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout()).then {
        $0.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    private(set) lazy var dataSource = makeDiffableDataSource(collectionView)
    //TODO: 버튼 Component 변경
    let addButton = UIButton().then {
        $0.setImage(.plus, for: .normal)
    }
    
    override init(frame: CGRect = .zero, step: OnboardingStep = .facility) {
        super.init(frame: frame, step: step)
        setLayout()
    }
}

extension OnboardingFacilityView {
    private func setLayout() {
        let stackView = UIStackView(arrangedSubviews: [negativeButton, positiveButton]).then {
            $0.axis = .vertical
            $0.spacing = 16
            $0.alignment = .center
        }
        
        addSubview(stackView)
        addSubview(collectionView)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(nextButton.snp.top).offset(-32)
        }
    }
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16
        configuration.contentInsetsReference = .layoutMargins
        
        return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            
            switch section {
            case .list:
                return self?.listSectionLayout()
            case .button:
                return self?.buttonSectionLayout()
            }
        }, configuration: configuration)
    }
    
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

extension OnboardingFacilityView {
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
    
    private func buttonSectionLayout() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(40)
            ))
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(40)),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}

extension OnboardingFacilityView {
    enum Section: Int {
        case list
        case button
    }
    
    nonisolated
    enum Item: Hashable {
        case list(Program)
        case button
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .list(let program):
                hasher.combine("list")
                hasher.combine(program)
                
            case .button:
                hasher.combine("button")
            }
        }
    }
}
