//
//  ConditionInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class ConditionInputViewController: UIViewController {
    private let conditionInputView: ConditionInputView
    private let reactor: CalendarReactor
    private let disposeBag = DisposeBag()

    init(reactor: CalendarReactor) {
        self.reactor = reactor
        conditionInputView = ConditionInputView(currentCondition: reactor.currentState.condition ?? .normal)

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = conditionInputView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bind()
    }
}

private extension ConditionInputViewController {
    func bind() {
        conditionInputView.closeButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        conditionInputView.rx.swipeDownToDismiss
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        [
            conditionInputView.veryGoodButton,
            conditionInputView.goodButton,
            conditionInputView.normalButton,
            conditionInputView.badButton,
            conditionInputView.worstButton
        ].forEach { button in
            button.rx.controlEvent(.touchUpInside)
                .bind(with: self) { owner, _ in
                    owner.conditionInputView.selectCondition(button.condition)
                }
                .disposed(by: disposeBag)
        }

        conditionInputView.saveButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.reactor.action.onNext(.updateCondition(owner.conditionInputView.selectedCondition))
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
