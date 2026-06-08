//
//  MenuGroupView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import SnapKit
import Then
import UIKit

final class MenuGroupView: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    init(rows: [UIView]) {
        super.init(frame: .zero)

        backgroundColor = UIColor(red: 0.979, green: 0.98, blue: 0.981, alpha: 1)
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for (index, row) in rows.enumerated() {
            stackView.addArrangedSubview(row)

            if index < rows.count - 1 {
                stackView.addArrangedSubview(MenuDivider())
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MenuDivider: UIView {
    private let lineView = UIView()
    private let pixelHeight = 1 / UIScreen.main.scale

    init(horizontalInset: CGFloat = 12) {
        super.init(frame: .zero)

        addSubview(lineView)
        lineView.backgroundColor = .gray100

        snp.makeConstraints {
            $0.height.equalTo(pixelHeight)
        }

        lineView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(horizontalInset)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
