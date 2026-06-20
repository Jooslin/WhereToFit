//
//  RegisteredProgramsView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import SnapKit
import Then
import UIKit

final class RegisteredProgramsView: UIView {
    let titleView = TitleView(text: "내가 등록한 프로그램", leftButtonImage: .arrowLeft, rightButtonImage: .edit)
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(RegisteredProgramCell.self, forCellWithReuseIdentifier: RegisteredProgramCell.reuseIdentifier)
    }

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

private extension RegisteredProgramsView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            collectionView
        ].forEach(addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(32)
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
