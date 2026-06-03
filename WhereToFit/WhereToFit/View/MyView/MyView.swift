//
//  MyView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/2/26.
//

import SnapKit
import Then
import UIKit

final class MyView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel(text: "마이페이지", config: .title20Semibold)

    private let profileCard = UIView().then {
        $0.backgroundColor = .primary25
        $0.layer.cornerRadius = 12
    }

    private let nameLabel = UILabel(text: "김아정님", config: .title20Semibold)
    private let addressLabel = UILabel(text: "송파구 거주", config: .body13Medium, color: .gray600)

    private let addressIcon = RoundImageView(image: .locationPinFilled, type: .circle).then {
        $0.tintColor = .gray600
    }

    private let profileButton = UIButton(type: .system).then {
        $0.setTitle("프로필 관리", for: .normal)
        $0.setTitleColor(.primary600, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.primary200.cgColor
        $0.layer.cornerRadius = 16
    }

    private let activityTitleLabel = UILabel(text: "내 활동", config: .body15)
    private let supportTitleLabel = UILabel(text: "고객지원 및 정보", config: .body15)
    private let accountTitleLabel = UILabel(text: "계정", config: .body15)

    private lazy var activityGroup = MyPageGroupView(rows: [
        MyPageMenuRow(title: "내가 등록한 프로그램", subtitle: "등록 내역 확인 · 일정 확인", showsIcon: true),
        MyPageMenuRow(title: "찜한 시설 및 프로그램", showsIcon: true),
        MyPageMenuRow(title: "운동 검사 결과", showsIcon: true)
    ])

    private lazy var supportGroup = MyPageGroupView(rows: [
        MyPageMenuRow(title: "알림설정"),
        MyPageMenuRow(title: "문의하기"),
        MyPageMenuRow(title: "버전 정보", trailingText: "v1.0.0"),
        MyPageMenuRow(title: "개인정보처리방침"),
        MyPageMenuRow(title: "이용약관"),
        MyPageMenuRow(title: "위치기반 서비스 이용약관"),
        MyPageMenuRow(title: "오픈소스 라이선스")
    ])

    private lazy var accountGroup = MyPageGroupView(rows: [
        MyPageMenuRow(title: "iCloud 동기화", accessory: .toggle)
    ])

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

private extension MyView {
    func setStyle() {
        backgroundColor = .white
        scrollView.showsVerticalScrollIndicator = false
    }

    func setLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel,
            profileCard,
            activityTitleLabel,
            activityGroup,
            supportTitleLabel,
            supportGroup,
            accountTitleLabel,
            accountGroup
        ].forEach(contentView.addSubview)

        [nameLabel, addressIcon, addressLabel, profileButton].forEach(profileCard.addSubview)

        scrollView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        profileCard.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(96)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(25)
            $0.leading.equalToSuperview().offset(16)
        }

        addressIcon.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(5)
            $0.size.equalTo(14)
        }

        addressLabel.snp.makeConstraints {
            $0.leading.equalTo(addressIcon.snp.trailing).offset(4)
            $0.centerY.equalTo(addressIcon)
        }

        profileButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(88)
            $0.height.equalTo(38)
        }

        activityTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileCard.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        activityGroup.snp.makeConstraints {
            $0.top.equalTo(activityTitleLabel.snp.bottom).offset(14)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        supportTitleLabel.snp.makeConstraints {
            $0.top.equalTo(activityGroup.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        supportGroup.snp.makeConstraints {
            $0.top.equalTo(supportTitleLabel.snp.bottom).offset(14)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        accountTitleLabel.snp.makeConstraints {
            $0.top.equalTo(supportGroup.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        accountGroup.snp.makeConstraints {
            $0.top.equalTo(accountTitleLabel.snp.bottom).offset(14)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(24)
        }
    }
}

private final class MyPageGroupView: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    init(rows: [MyPageMenuRow]) {
        super.init(frame: .zero)

        backgroundColor = UIColor(red: 0.979, green: 0.98, blue: 0.981, alpha: 1)
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for (index, row) in rows.enumerated() {
            stackView.addArrangedSubview(row)

            if index < rows.count - 1 {
                stackView.addArrangedSubview(MyPageDivider())
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MyPageMenuRow: UIView {
    enum Accessory {
        case disclosure
        case toggle
    }

    private let titleLabel: UILabel
    private let subtitleLabel: UILabel?
    private let leadingIcon: UIView?
    private let accessoryView: UIView

    init(
        title: String,
        subtitle: String? = nil,
        trailingText: String? = nil,
        showsIcon: Bool = false,
        accessory: Accessory = .disclosure
    ) {
        titleLabel = UILabel(text: title, config: .body14Regular)

        if let subtitle {
            subtitleLabel = UILabel(text: subtitle, config: .body12Medium, color: .gray500)
        } else {
            subtitleLabel = nil
        }

        if showsIcon {
            leadingIcon = UIView().then {
                $0.backgroundColor = .gray100
                $0.layer.cornerRadius = 16
            }
        } else {
            leadingIcon = nil
        }

        switch accessory {
        case .disclosure:
            accessoryView = UIImageView(image: UIImage(resource: .arrow)).then {
                $0.tintColor = .gray200
                $0.contentMode = .scaleAspectFit
            }
        case .toggle:
            accessoryView = UISwitch().then {
                $0.isOn = false
            }
        }

        super.init(frame: .zero)

        setLayout(trailingText: trailingText)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MyPageMenuRow {
    func setLayout(trailingText: String?) {
        addSubview(titleLabel)
        addSubview(accessoryView)

        let hasIcon = leadingIcon != nil
        let rowHeight: CGFloat = hasIcon ? 56 : 48

        snp.makeConstraints {
            $0.height.equalTo(rowHeight)
        }

        if let leadingIcon {
            addSubview(leadingIcon)
            leadingIcon.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(12)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(32)
            }
        }

        accessoryView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()

            if accessoryView is UIImageView {
                $0.width.equalTo(24)
                $0.height.equalTo(24)
            }
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(hasIcon ? 52 : 12)

            if subtitleLabel == nil {
                $0.centerY.equalToSuperview()
            } else {
                $0.top.equalToSuperview().offset(10)
            }
        }

        if let subtitleLabel {
            addSubview(subtitleLabel)
            subtitleLabel.snp.makeConstraints {
                $0.leading.equalTo(titleLabel)
                $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            }
        }

        if let trailingText {
            let trailingLabel = UILabel(text: trailingText, config: .body12Regular, color: .gray500)
            addSubview(trailingLabel)
            trailingLabel.snp.makeConstraints {
                $0.trailing.equalTo(accessoryView.snp.leading).offset(-10)
                $0.centerY.equalToSuperview()
            }
        }
    }
}

private final class MyPageDivider: UIView {
    private let lineView = UIView()
    private let pixelHeight = 1 / UIScreen.main.scale

    init() {
        super.init(frame: .zero)

        addSubview(lineView)
        lineView.backgroundColor = .gray100

        snp.makeConstraints {
            $0.height.equalTo(pixelHeight)
        }

        lineView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(12)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
