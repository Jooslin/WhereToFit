//
//  RegisteredProgramsView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import SnapKit
import UIKit

final class RegisteredProgramsView: UIView {
    let titleView = TitleView(text: "내가 등록한 프로그램", leftButtonImage: UIImage(resource: .arrowLeft))

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

private extension RegisteredProgramsView {
    func setStyle() {
        backgroundColor = .white
    }

    func setLayout() {
        addSubview(titleView)

        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
    }
}
