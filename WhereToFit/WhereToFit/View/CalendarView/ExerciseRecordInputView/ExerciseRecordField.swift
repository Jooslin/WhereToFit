//
//  ExerciseRecordField.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ExerciseRecordField: UIView {
    private let titleLabel: UILabel
    fileprivate let textField = DesignTextField().then {
        $0.font = LabelConfiguration.body14Medium.font
    }

    var text: String? {
        get {
            textField.text
        }
        set {
            textField.text = newValue
        }
    }

    init(title: String, text: String? = nil, placeholder: String? = nil) {
        titleLabel = UILabel(text: title, config: .body14Medium, color: .gray700)

        super.init(frame: .zero)

        textField.text = text
        if let placeholder {
            textField.setPlaceholder(text: placeholder)
        }

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setReadOnly() {
        textField.inputView = UIView()
        textField.tintColor = .clear
    }
}

private extension ExerciseRecordField {
    func setLayout() {
        [
            titleLabel,
            textField
        ].forEach(addSubview)

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.trailing.equalToSuperview().priority(999)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.bottom.equalToSuperview()
            $0.trailing.equalToSuperview().priority(999)
            $0.height.equalTo(48)
        }
    }
}

extension Reactive where Base == ExerciseRecordField {
    var editingDidBegin: ControlEvent<Void> {
        base.textField.rx.controlEvent(.editingDidBegin)
    }
}
