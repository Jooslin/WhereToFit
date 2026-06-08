//
//  ProfileManagementView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import SnapKit
import Then
import UIKit

// TODO: 선택시 버튼 색 바뀌도록
final class ProfileManagementView: UIView {
    let titleView = TitleView(text: "프로필 관리", leftButtonImage: UIImage(systemName: "chevron.left"))

    private let nicknameField = ProfileInputField(title: "닉네임", text: "김아정")
    private let birthDateField = ProfileInputField(title: "생년월일", text: "19980609")
    private let genderField = ProfileGenderField()
    private let addressField = ProfileInputField(title: "거주 지역 (선택)", placeholder: "주소 찾기")

    private let heightField = ProfileInputField(title: "키 (선택)", placeholder: "키를 입력해주세요")
    private let weightField = ProfileInputField(title: "몸무게 (선택)", placeholder: "몸무게를 입력해주세요")

    private let bodyInfoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 23
        $0.distribution = .fillEqually
    }
    
    private let saveButton = DesignButton(config: .largeFilledGray).then {
        $0.title = "저장하기"
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

private extension ProfileManagementView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        [
            titleView,
            nicknameField,
            birthDateField,
            genderField,
            addressField,
            bodyInfoStackView,
            saveButton
        ].forEach(addSubview)

        bodyInfoStackView.addArrangedSubview(heightField)
        bodyInfoStackView.addArrangedSubview(weightField)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(11)
            $0.horizontalEdges.equalToSuperview()
        }

        nicknameField.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(42)
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

        addressField.snp.makeConstraints {
            $0.top.equalTo(genderField.snp.bottom).offset(26)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        bodyInfoStackView.snp.makeConstraints {
            $0.top.equalTo(addressField.snp.bottom).offset(26)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(21)
            $0.height.equalTo(48)
        }
    }
}

private final class ProfileInputField: UIView {
    private let titleLabel: UILabel
    private let textField = UITextField().then {
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

private final class ProfileGenderField: UIView {
    private let titleLabel = UILabel(text: "성별", config: .body14Medium, color: .gray600)
    
    private let maleButton = DesignButton(config: .smallFilledLightGray).then {
        $0.title = "남성"
    }
    private let femaleButton = DesignButton(config: .smallFilledLightGray).then {
        $0.isSelected = true
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
