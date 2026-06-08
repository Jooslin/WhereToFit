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


// MARK: - 커스텀 서치바
final class SearchBar: UIView {
    
    
    // MARK: - UI Components (화면 요소)
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

    
    // MARK: - Properties (속성)
    // 뷰의 기본 크기 지정
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    // 입력 텍스트 계산 프로퍼티
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    
    // MARK: - Initialization (초기화)
    init(placeholder: String) {
        super.init(frame: .zero)
        configure(placeholder: placeholder)
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Lifecycle (뷰 생명주기)
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func configure(placeholder: String) {
        backgroundColor = .systemBackground
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


// MARK: - RxSwift Extension
extension Reactive where Base: SearchBar {
    
    // 서치바 텍스트 실시간 관찰, 값 삽입
    var text: ControlProperty<String?> {
        base.textField.rx.text
    }
    
    // 검색 했을 때 이벤트 방출
    var search: ControlEvent<String?> {
        let source = base.textField.rx
            .controlEvent(.editingDidEndOnExit)
            .map { base.textField.text } // 현재 텍스트 값 추출
        return ControlEvent(events: source)
    }
}
