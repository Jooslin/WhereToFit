//
//  WeightInputViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import UIKit

final class WeightInputViewController: UIViewController {
    var onSave: ((CalendarReactor.WeightValue) -> Void)?

    private let weightInputView: WeightInputView

    init(currentWeight: CalendarReactor.WeightValue) {
        weightInputView = WeightInputView(currentWeight: currentWeight)

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

        setAction()
    }
}

private extension WeightInputViewController {
    func setAction() {
        weightInputView.closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        weightInputView.saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc func saveButtonTapped() {
        onSave?(weightInputView.selectedWeight)
        dismiss(animated: true)
    }
}
