//
//  FacilityCountMarkerView.swift
//  WhereToFit
//
//  Created by 김주희 on 6/12/26.
//

import UIKit
import Then

/// 지도를 축소했을 때 여러 시설을 한 마커 안에 카테고리별 개수로 보여주는 뷰입니다.
/// Naver Map 마커는 UIView를 직접 올릴 수 없어서 `renderedImage()`로 이미지화한 뒤 marker icon으로 사용합니다.
final class FacilityCountMarkerView: UIView {
    struct Item {
        let icon: UIImage?
        let count: Int
    }

    static let fixedWidth: CGFloat = 65

    private enum Metric {
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 8
        static let rowSpacing: CGFloat = 4
        static let rowHeight: CGFloat = 20
        static let iconSize: CGFloat = 20
        static let iconToCountSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let compactCountThreshold = 100
        static let compactCountFontSize: CGFloat = 13
        static let minimumCountScaleFactor: CGFloat = 0.65
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = Metric.rowSpacing
        $0.alignment = .fill
        $0.distribution = .fill
    }

    private var items: [Item] = []

    init(items: [Item] = []) {
        super.init(frame: .zero)
        configureLayout()
        configure(items: items)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [Item]) {
        self.items = items
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        items.forEach { item in
            stackView.addArrangedSubview(makeRow(item: item))
        }
    }

    func renderedImage() -> UIImage {
        // 실제 마커 크기에 맞춰 layout을 끝낸 뒤 캡처해야 글자와 아이콘이 잘리지 않습니다.
        let size = fittingMarkerSize
        bounds = CGRect(origin: .zero, size: size)
        setNeedsLayout()
        layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            layer.render(in: context.cgContext)
        }
    }

    var fittingMarkerSize: CGSize {
        let rowCount = max(items.count, 1)
        let height = Metric.verticalInset * 2
            + CGFloat(rowCount) * Metric.rowHeight
            + CGFloat(max(rowCount - 1, 0)) * Metric.rowSpacing
        return CGSize(width: Self.fixedWidth, height: height)
    }

    private func configureLayout() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        layer.cornerRadius = Metric.cornerRadius
        layer.borderColor = UIColor.primary100.cgColor
        layer.borderWidth = Metric.borderWidth
        layer.masksToBounds = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Metric.verticalInset),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metric.verticalInset)
        ])
    }

    private func makeRow(item: Item) -> UIView {
        let rowView = UIView()
        let imageView = UIImageView(image: item.icon).then {
            $0.contentMode = .scaleAspectFit
        }
        let countLabel = UILabel(text: "\(item.count)", config: .title16, color: .gray600).then {
            if item.count >= Metric.compactCountThreshold {
                $0.font = $0.font.withSize(Metric.compactCountFontSize)
            }
            $0.textAlignment = .right
            $0.numberOfLines = 1
            $0.lineBreakMode = .byClipping
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = Metric.minimumCountScaleFactor
            $0.baselineAdjustment = .alignCenters
        }

        rowView.addSubview(imageView)
        rowView.addSubview(countLabel)
        rowView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalToConstant: Metric.rowHeight),

            imageView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: Metric.horizontalInset),
            imageView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: Metric.iconSize),
            imageView.heightAnchor.constraint(equalToConstant: Metric.iconSize),

            countLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -Metric.horizontalInset),
            countLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: Metric.iconToCountSpacing)
        ])

        return rowView
    }
}
