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
    private let interactivePopGestureDelegate = InteractivePopGestureDelegate()
    
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
        configureInteractivePopGesture()
        configureKeyboardDismissOnTap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        configureInteractivePopGesture()
    }

    func bind(reactor: R) {}
}

private extension BaseViewController {
    func configureInteractivePopGesture() {
        interactivePopGestureDelegate.attach(to: navigationController)
    }

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

final class InteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?

    func attach(to navigationController: UINavigationController?) {
        self.navigationController = navigationController
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController,
              gestureRecognizer === navigationController.interactivePopGestureRecognizer else {
            return true
        }

        // 루트 화면에서는 pop할 대상이 없어 제스처를 막아 네비게이션 freeze를 방지합니다.
        return navigationController.viewControllers.count > 1
            && navigationController.transitionCoordinator == nil
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
