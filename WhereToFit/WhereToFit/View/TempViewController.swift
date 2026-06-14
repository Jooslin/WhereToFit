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
    let networkService = NetworkService()
    private lazy var sportsRepository = SportsRepository(networkService: networkService)
    private lazy var weatherRepository = WeatherRepository(networkService: networkService)
    
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .close)
    
    let leftButton = IconButton(config: .locationIcon, style: .bothImage).then {
        $0.normalImage = .locationPinFilled
        $0.title = "지역"
        $0.normalRightImage = .arrowDown
    }
    
    let favoriteButton = IconButton(config: .icon, selectedConfig: .icon, style: .icon, iconSize: .compact).then {
        $0.normalImage = .heart
        $0.selectedImage = .heartFilled
        $0.isSelected = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(titleView)
        view.addSubview(leftButton)
        view.addSubview(favoriteButton)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        leftButton.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        favoriteButton.snp.makeConstraints {
            $0.top.equalTo(leftButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        favoriteButton.applyColor(color: .white)
    }
    
    override func bind(reactor: TempReactor) {
        titleView.rx.leftButtonTap
            .subscribe(onNext: {
                print("leftButtonTapped")
            })
            .disposed(by: disposeBag)
        
        favoriteButton.rx.tap
            .subscribe(onNext: { [favoriteButton] in
                favoriteButton.isSelected.toggle()
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

#Preview {
    TempViewController(reactor: TempReactor())
}
