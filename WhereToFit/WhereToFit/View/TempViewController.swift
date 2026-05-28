//
//  MainViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 5/20/26.
//

import UIKit
import ReactorKit
import SnapKit
import Then

final class TempViewController: BaseViewController<TempReactor> {
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .close)
    let largeBorderButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "large border blue"
    }
    let mediumBlueButton = DesignButton(config: .mediumFilledBlue).then {
        $0.title = "medium blue"
    }
    let smallGrayButton = DesignButton(config: .smallFilledGray).then {
        $0.title = "gray"
    }
    let smallLightGrayButton = DesignButton(config: .smallFilledLightGray).then {
        $0.title = "light gray"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let smallButtons = UIStackView(arrangedSubviews: [smallGrayButton, smallLightGrayButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
        }
        
        let buttons = UIStackView(arrangedSubviews: [largeBorderButton, mediumBlueButton, smallButtons]).then {
            $0.axis = .vertical
            $0.spacing = 5
        }

        view.addSubview(titleView)
        view.addSubview(buttons)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        buttons.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
    }
    
    override func bind(reactor: TempReactor) {
        titleView.rx.leftButtonTap
            .subscribe(onNext: {
                print("leftButtonTapped")
            })
            .disposed(by: disposeBag)
        
        largeBorderButton.rx.tap
            .subscribe(onNext: {
                print("largeBorderButtonTapped")
            })
            .disposed(by: disposeBag)
    }
}

final class TempReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        
    }
    
    struct State {}
}
