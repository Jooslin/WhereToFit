//
//  TitleView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/28/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

/**
 공통으로 사용할 TitleView입니다.
 각 화면에서 생성하여 바로 사용하거나 디자인에 맞게 커스텀하여 사용합니다.
 
 Reactive 확장을 통해 아래와 같이 외부에서도 버튼의 이벤트를 구독할 수 있습니다.
 ```swift
 class TempViewController {
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .close)
 
    override func bind(reactor: TempReactor) {
        titleView.rx.leftButtonTap
            .subscribe(onNext: {
                print("leftButtonTapped")
            })
            .disposed(by: disposeBag)
    }
 }
 ```

 - Parameters:
    - text: 타이틀 레이블에 사용될 텍스트 (nil 값일 경우 미표시. 기본값은 nil)
    - leftButtonImage: 왼쪽 버튼에 사용할 이미지 (nil 값일 경우 미표시. 기본값은 nil)
    - rightButtonImage: 오른쪽 버튼에 사용할 이미지 (nil 값일 경우 미표시. 기본값은 nil)
 */
class TitleView: UIView {
    private let titleLabel = UILabel(text: "", config: .title16, color: .gray900).then {
        $0.textAlignment = .center
    }
    
    fileprivate let leftButton = UIButton(configuration: .plain())
    fileprivate let rightButton = UIButton(configuration: .plain())
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 48) // 세로 크기만 부여
    }
    
    init(text: String? = nil, leftButtonImage: UIImage? = nil, rightButtonImage: UIImage? = nil) {
        super.init(frame: .zero)
        
        configure(text: text, leftButtonImage: leftButtonImage, rightButtonImage: rightButtonImage)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitleView {
    private func configure(text: String? = nil, leftButtonImage: UIImage? = nil, rightButtonImage: UIImage? = nil) {
        if let text {
            titleLabel.text = text
        } else {
            titleLabel.isHidden = true
        }
        
        if let leftButtonImage {
            leftButton.setImage(leftButtonImage, for: .normal)
        } else {
            leftButton.isHidden = true
        }
        
        if let rightButtonImage {
            rightButton.setImage(rightButtonImage, for: .normal)
        } else {
            rightButton.isHidden = true
        }
    }
    
    private func setLayout() {
        addSubview(titleLabel)
        addSubview(leftButton)
        addSubview(rightButton)
        
        leftButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.verticalEdges.equalToSuperview().inset(13)
            $0.centerX.equalToSuperview()
        }
        
        rightButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
    
    // 색상 변경 메서드
    func apply(color: UIColor) {
        titleLabel.textColor = color
        leftButton.configuration?.baseForegroundColor = color
        rightButton.configuration?.baseForegroundColor = color
    }
}

extension Reactive where Base: TitleView {
    var leftButtonTap: ControlEvent<Void> {
        base.leftButton.rx.tap
    }
    
    var rightButtonTap: ControlEvent<Void> {
        base.rightButton.rx.tap
    }
}
