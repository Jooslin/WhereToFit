//
//  SearchBar.swift
//  WhereToFit
//
//  Created by 김주희 on 6/2/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxSwift

final class SearchBar: UIView {
    fileprivate let textField = UITextField().then {
        $0.font = LabelConfiguration.body14Regular.font
        $0.textColor = .gray900
        $0.clearButtonMode = .whileEditing // 글자 입력중일때 우측에 'x' 지우기 버튼 표시
        $0.returnKeyType = .search // 키보드 엔터키 모양을 '검색' 모양으로 변경
    }

    private let searchImageView = UIImageView(image: .search.withRenderingMode(.alwaysTemplate)).then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .gray400
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    init(placeholder: String) {
        super.init(frame: .zero)
        configure(placeholder: placeholder)
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func configure(placeholder: String) {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray200.cgColor
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.gray200]
        )
    }

    private func setLayout() {
        addSubview(textField)
        addSubview(searchImageView)

        searchImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(searchImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }
}

extension Reactive where Base: SearchBar {
    var text: ControlProperty<String?> {
        base.textField.rx.text
    }
}
