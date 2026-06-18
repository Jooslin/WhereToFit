//
//  TouchableDesignTextField.swift
//  WhereToFit
//
//  Created by 변예린 on 6/18/26.
//

import UIKit
import RxCocoa
import RxSwift

final class TouchableDesignTextField: DesignTextField {
    fileprivate let tapGesture = UITapGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tintColor = .clear
        delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TouchableDesignTextField: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        false
    }
}

extension Reactive where Base: TouchableDesignTextField {
    var tap: ControlEvent<Void> {
        ControlEvent(events: base.tapGesture.rx.event.map { _ in })
    }
}
