//
//  ExerciseResultView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import SnapKit
import Then
import UIKit

final class ExerciseResultView: UIView {
    let titleView = TitleView(text: "운동 검사 결과", leftButtonImage: UIImage(resource: .arrowLeft))

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    private let contentView = UIView()
    private let summaryCardView = PrimaryGradientCardView()
    private let summaryStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }
    private let retryButton = UIButton(type: .system).then {
        $0.setTitle("검사 다시하기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.backgroundColor = .primary400
        $0.layer.cornerRadius = 19
    }
    private let recommendationTitleLabel = UILabel(text: "AI 맞춤 운동 추천", config: .body16Medium)
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout()).then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.showsVerticalScrollIndicator = false
        $0.isScrollEnabled = false
        $0.dataSource = self
        $0.register(ExerciseRecommendationCell.self, forCellWithReuseIdentifier: ExerciseRecommendationCell.reuseIdentifier)
    }

    private var recommendationItems: [ExerciseResultReactor.RecommendationItem] = []
    private var collectionViewHeightConstraint: Constraint?

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

extension ExerciseResultView {
    func updateSummaryItems(_ items: [ExerciseResultReactor.SummaryItem]) {
        summaryStackView.arrangedSubviews.forEach {
            summaryStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        items.forEach {
            summaryStackView.addArrangedSubview(ExerciseSummaryRow(item: $0))
        }
    }

    func updateRecommendationItems(_ items: [ExerciseResultReactor.RecommendationItem]) {
        recommendationItems = items
        collectionView.reloadData()
        collectionViewHeightConstraint?.update(offset: CGFloat(items.count) * 70)
    }
}

private extension ExerciseResultView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            scrollView
        ].forEach(addSubview)

        scrollView.addSubview(contentView)

        [
            summaryCardView,
            recommendationTitleLabel,
            collectionView
        ].forEach(contentView.addSubview)

        [
            summaryStackView,
            retryButton
        ].forEach(summaryCardView.addSubview)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        summaryCardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        summaryStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(22)
            $0.horizontalEdges.equalToSuperview().inset(12)
        }

        retryButton.snp.makeConstraints {
            $0.top.equalTo(summaryStackView.snp.bottom).offset(18)
            $0.bottom.equalTo(summaryCardView).inset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(118)
            $0.height.equalTo(38)
        }

        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(summaryCardView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(14)
            $0.horizontalEdges.equalToSuperview().inset(16)
            collectionViewHeightConstraint = $0.height.equalTo(0).constraint
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(70)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(70)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension ExerciseResultView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recommendationItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ExerciseRecommendationCell.reuseIdentifier,
            for: indexPath
        ) as? ExerciseRecommendationCell else {
            return UICollectionViewCell()
        }

        cell.configure(item: recommendationItems[indexPath.item], hidesDivider: indexPath.item == recommendationItems.count - 1)
        return cell
    }
}

private final class ExerciseSummaryRow: UIView {
    private let titleLabel: UILabel
    private let valueLabel: UILabel

    init(item: ExerciseResultReactor.SummaryItem) {
        titleLabel = UILabel(text: item.title, config: .body14Regular, color: .gray600)
        valueLabel = UILabel(text: item.value, config: .body14Medium, color: .gray900).then {
            $0.textAlignment = .right
        }

        super.init(frame: .zero)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ExerciseSummaryRow {
    func setLayout() {
        [
            titleLabel,
            valueLabel
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.leading.verticalEdges.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.verticalEdges.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
    }
}
