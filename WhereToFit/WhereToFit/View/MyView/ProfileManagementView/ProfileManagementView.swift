//
//  ProfileManagementView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import SnapKit
import Then
import UIKit

final class ProfileManagementView: UIView {
    let titleView = TitleView(text: "프로필 관리", leftButtonImage: UIImage(systemName: "chevron.left"))

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .interactive
    }
    private let contentView = UIView()
    let nicknameField = ProfileInputField(title: "닉네임")
    let birthDateField = ProfileInputField(title: "생년월일", placeholder: "ex)19991208").then {
        $0.textField.keyboardType = .numberPad
    }
    let genderField = ProfileGenderField()
    let heightField = ProfileInputField(title: "키 (선택)", placeholder: "키를 입력해주세요").then {
        $0.textField.keyboardType = .decimalPad
    }
    let weightField = ProfileInputField(title: "몸무게 (선택)", placeholder: "몸무게를 입력해주세요").then {
        $0.textField.keyboardType = .decimalPad
    }

    private let bodyInfoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 23
        $0.distribution = .fillEqually
    }
    
    let saveButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "저장하기"
        $0.isEnabled = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileManagementView {
    func update(
        nickname: String,
        birthday: String,
        gender: UserGender,
        height: String,
        weight: String
    ) {
        nicknameField.textField.text = nickname
        birthDateField.textField.text = birthday
        genderField.update(gender: gender)
        heightField.textField.text = height
        weightField.textField.text = weight
    }

    func updateSaveButton(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
    }

    func updateKeyboardBottomInset(_ bottomInset: CGFloat) {
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    func scrollToVisible(_ field: ProfileInputField) {
        let fieldFrame = field.convert(field.bounds, to: scrollView)
        scrollView.scrollRectToVisible(fieldFrame.insetBy(dx: 0, dy: -12), animated: true)
    }
}

private extension ProfileManagementView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            scrollView,
            saveButton
        ].forEach(addSubview)

        scrollView.addSubview(contentView)

        [
            nicknameField,
            birthDateField,
            genderField,
            bodyInfoStackView
        ].forEach(contentView.addSubview)

        bodyInfoStackView.addArrangedSubview(heightField)
        bodyInfoStackView.addArrangedSubview(weightField)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(11)
            $0.horizontalEdges.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(saveButton.snp.top).offset(-16)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        nicknameField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(42)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        birthDateField.snp.makeConstraints {
            $0.top.equalTo(nicknameField.snp.bottom).offset(26)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        genderField.snp.makeConstraints {
            $0.top.equalTo(birthDateField.snp.bottom).offset(26)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        bodyInfoStackView.snp.makeConstraints {
            $0.top.equalTo(genderField.snp.bottom).offset(26)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(21)
            $0.height.equalTo(48)
        }
    }
}

final class ProfileInputField: UIView {
    private let titleLabel: UILabel
    let textField = UITextField().then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 8
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .gray900
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        $0.leftViewMode = .always
    }

    init(title: String, text: String? = nil, placeholder: String? = nil) {
        titleLabel = UILabel(text: title, config: .body14Medium, color: .gray600)
        super.init(frame: .zero)

        textField.text = text
        textField.placeholder = placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [.foregroundColor: UIColor.gray300]
        )

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ProfileInputField {
    func setLayout() {
        addSubview(titleLabel)
        addSubview(textField)

        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(48)
        }
    }
}

final class ProfileGenderField: UIView {
    private let titleLabel = UILabel(text: "성별", config: .body14Medium, color: .gray600)
    
    let maleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "남성"
    }
    let femaleButton = DesignButton(config: .smallFilledLightGray, selectedConfig: .selectedSmallBorderBlue).then {
        $0.title = "여성"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileGenderField {
    func update(gender: UserGender) {
        maleButton.isSelected = gender == .male
        femaleButton.isSelected = gender == .female
    }
}

private extension ProfileGenderField {
    func setLayout() {
        addSubview(titleLabel)
        addSubview(maleButton)
        addSubview(femaleButton)

        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }

        maleButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.bottom.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(38)
        }

        femaleButton.snp.makeConstraints {
            $0.leading.equalTo(maleButton.snp.trailing).offset(10)
            $0.centerY.equalTo(maleButton)
            $0.width.height.equalTo(maleButton)
        }
    }
}
