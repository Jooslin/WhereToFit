//
//  ViewController.swift
//  Gymap
//
//  Created by 변예린 on 5/19/26.
//

import UIKit
import RxCocoa
import RxFlow
import RxRelay
import RxSwift
import ReactorKit

class BaseViewController<R: Reactor>: UIViewController, Stepper, ReactorKit.View {
    typealias State = R.State
    typealias Action = R.Action
    
    let steps = PublishRelay<Step>()
    var disposeBag = DisposeBag()
    private let keyboardDismissTapDelegate = KeyboardDismissTapDelegate()
    
    init(reactor: R? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.isHidden = true
        
        // 네비게이션 바가 숨겨져도 스와이프로 뒤로 가기가 가능하도록 설정
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        configureKeyboardDismissOnTap()
    }

    func bind(reactor: R) {}
}

private extension BaseViewController {
    func configureKeyboardDismissOnTap() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = keyboardDismissTapDelegate
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }
}

private final class KeyboardDismissTapDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view?.isTextInputViewOrDescendant ?? false)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private extension UIView {
    var isTextInputViewOrDescendant: Bool {
        var currentView: UIView? = self

        while let view = currentView {
            if view is UITextField || view is UITextView || view is UISearchBar {
                return true
            }

            currentView = view.superview
        }

        return false
    }
}
