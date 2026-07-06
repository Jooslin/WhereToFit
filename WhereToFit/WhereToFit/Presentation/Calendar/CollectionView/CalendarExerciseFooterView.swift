//
//  CalendarExerciseFooterView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CalendarExerciseFooterView: UICollectionReusableView {
    static let reuseIdentifier = "CalendarExerciseFooterView"

    private(set) var disposeBag = DisposeBag()

    fileprivate let recordButton = DesignButton(config: .largeFilledLightGray).then {
        $0.title = "운동 기록하기"
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray100.cgColor
        $0.layer.cornerRadius = 20
        $0.layer.masksToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()
    }
}

private extension CalendarExerciseFooterView {
    func setLayout() {
        addSubview(recordButton)

        recordButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
}

extension Reactive where Base == CalendarExerciseFooterView {
    var recordButtonTap: ControlEvent<Void> {
        base.recordButton.rx.tap
    }
}
