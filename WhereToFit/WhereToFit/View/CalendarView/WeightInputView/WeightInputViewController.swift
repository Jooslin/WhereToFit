//
//  WeightInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class WeightInputViewController: UIViewController {
    private let weightInputView: WeightInputView
    private let reactor: CalendarReactor
    private let disposeBag = DisposeBag()

    init(reactor: CalendarReactor) {
        self.reactor = reactor
        weightInputView = WeightInputView(
            currentWeight: reactor.currentState.weight ?? CalendarReactor.WeightValue(integer: 54, decimal: 2)
        )

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = weightInputView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bind()
    }
}

private extension WeightInputViewController {
    func bind() {
        weightInputView.closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        weightInputView.rx.swipeDownToDismiss
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        weightInputView.saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.reactor.action.onNext(.updateWeight(owner.weightInputView.selectedWeight))
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
