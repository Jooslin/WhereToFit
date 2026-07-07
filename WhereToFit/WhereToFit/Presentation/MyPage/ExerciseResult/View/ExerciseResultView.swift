//
//  ExerciseResultView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import RxCocoa
import RxSwift
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
    var retryButtonTap: ControlEvent<Void> {
        retryButton.rx.tap
    }

    func updateSummaryItems(_ items: [ExerciseResultReactor.SummaryItem]) {
        summaryStackView.arrangedSubviews.forEach {
            summaryStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        items.forEach {
            summaryStackView.addArrangedSubview(ExerciseSummaryRow(item: $0))
        }
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
            summaryCardView
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
            $0.bottom.equalToSuperview().inset(24)
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
