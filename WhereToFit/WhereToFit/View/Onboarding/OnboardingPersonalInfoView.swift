//
//  OnboardingPersonalInfoView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/5/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class OnboardingPersonalInfoView: OnboardingBaseView {
    let nicknameTextField = DesignTextField().then {
        $0.setPlaceholder(text: "닉네임을 입력해주세요")
    }
    let birthdayTextField = DesignTextField().then {
        $0.setPlaceholder(text: "ex)19991208")
        $0.keyboardType = .numberPad
    }
    let maleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "남성"
    }
    let femaleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "여성"
    }
    let residenceTextField = TouchableDesignTextField().then {
        $0.setPlaceholder(text: "주소 찾기")
    }
    let heightTextField = DesignTextField().then {
        $0.setPlaceholder(text: "키를 입력해주세요")
        $0.keyboardType = .decimalPad
    }
    let weightTextField = DesignTextField().then {
        $0.setPlaceholder(text: "몸무게를 입력해주세요")
        $0.keyboardType = .decimalPad
    }

    override init(frame: CGRect = .zero, step: OnboardingStep = .personalInfo) {
        super.init(frame: .zero, step: step)
        setLayout()
    }
}

extension OnboardingPersonalInfoView {
    private func setLayout() {
        let buttonStackView = UIStackView(arrangedSubviews: [maleButton, femaleButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
        }

        let nicknameStackView = makeStackView(title: "닉네임", view: nicknameTextField)
        let birthdayStackView = makeStackView(title: "생년월일", view: birthdayTextField)
        let genderStackView = makeStackView(title: "성별", view: buttonStackView)
        let residenceStackView = makeStackView(title: "거주 지역 (선택)", view: residenceTextField)

        let heightStackView = makeStackView(title: "키 (선택)", view: heightTextField)
        let weightStackView = makeStackView(title: "몸무게 (선택)", view: weightTextField)
        let bodyStackView = UIStackView(arrangedSubviews: [heightStackView, weightStackView]).then {
            $0.axis = .horizontal
            $0.spacing = 22
            $0.distribution = .fillEqually
        }

        let stackView = UIStackView(arrangedSubviews: [nicknameStackView, birthdayStackView, genderStackView, residenceStackView, bodyStackView]).then {
            $0.axis = .vertical
            $0.spacing = 20
            $0.alignment = .leading
            $0.distribution = .fill
        }

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.top.equalTo(subTitleLabel.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        nicknameTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }

        birthdayTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }

        residenceTextField.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }

        bodyStackView.snp.makeConstraints {
            $0.width.equalTo(stackView.snp.width)
        }

        heightTextField.snp.makeConstraints {
            $0.width.equalTo(heightStackView.snp.width)
        }

        weightTextField.snp.makeConstraints {
            $0.width.equalTo(weightStackView.snp.width)
        }
    }

    private func makeStackView(title: String, view: UIView) -> UIStackView {
        let titleLabel = UILabel(text: title, config: .body14Medium)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, view]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 6
        }

        return stackView
    }
}

//MARK: Reactive
extension Reactive where Base: OnboardingPersonalInfoView {
    var nicknameTextFieldEditingDidEnd: ControlEvent<String> {
        let source = base.nicknameTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(base.nicknameTextField.rx.text.orEmpty)

        return ControlEvent(events: source)
    }

    var birthdayTextFieldEditingDidEnd: ControlEvent<String> {
        let source = base.birthdayTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(base.birthdayTextField.rx.text.orEmpty)

        return ControlEvent(events: source)
    }

    var genderButtonTap: ControlEvent<String> {
        let event = Observable.merge([
            base.maleButton.rx.tap.compactMap { base.maleButton.title },
            base.femaleButton.rx.tap.compactMap {
                base.femaleButton.title
            }
        ])

        return ControlEvent(events: event)
    }

    var weightTextFieldEditingDidEnd: ControlEvent<String> {
        let source = base.weightTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(base.weightTextField.rx.text.orEmpty)

        return ControlEvent(events: source)
    }

    var heightTextFieldEditingDidEnd: ControlEvent<String> {
        let source = base.heightTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(base.heightTextField.rx.text.orEmpty)

        return ControlEvent(events: source)
    }
}
