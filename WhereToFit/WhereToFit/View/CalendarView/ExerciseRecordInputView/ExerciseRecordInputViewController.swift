//
//  ExerciseRecordInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import RxCocoa
import RxSwift
import UIKit

final class ExerciseRecordInputViewController: UIViewController {
    private let exerciseRecordInputView = ExerciseRecordInputView()
    private let disposeBag = DisposeBag()

    override func loadView() {
        view = exerciseRecordInputView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bind()
    }
}

private extension ExerciseRecordInputViewController {
    func bind() {
        exerciseRecordInputView.closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        exerciseRecordInputView.saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
