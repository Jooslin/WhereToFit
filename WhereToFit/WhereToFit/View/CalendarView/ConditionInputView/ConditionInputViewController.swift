//
//  ConditionInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import RxCocoa
import RxSwift
import UIKit

final class ConditionInputViewController: UIViewController {
    var onSave: ((CalendarReactor.ConditionValue) -> Void)?

    private let conditionInputView: ConditionInputView
    private let disposeBag = DisposeBag()

    init(currentCondition: CalendarReactor.ConditionValue) {
        conditionInputView = ConditionInputView(currentCondition: currentCondition)

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
            .bind(with: self) { owner, _ in
                owner.onSave?(owner.conditionInputView.selectedCondition)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
