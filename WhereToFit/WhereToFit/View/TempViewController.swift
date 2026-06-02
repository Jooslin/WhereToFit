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
    let largeBorderButton = DesignButton(config: .largeBorderBlue).then {
        $0.title = "large border blue"
    }
    let mediumBlueButton = DesignButton(config: .mediumFilledBlue)
    
    let smallGrayButton = DesignButton(config: .smallFilledGray).then {
        $0.title = "gray"
    }
    let smallLightGrayButton = DesignButton(config: .smallFilledLightGray).then {
        $0.title = "light gray"
    }
    
    let circleImageView = RoundImageView(image: .dateFilled, type: .circle).then { $0.backgroundColor = .red }
    
    let roundedImageView = RoundImageView(image: .dateFilled, type: .roundSquare).then { $0.backgroundColor = .red }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchSupabaseSmokeTest()

        let smallButtons = UIStackView(arrangedSubviews: [smallGrayButton, smallLightGrayButton]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        let buttons = UIStackView(arrangedSubviews: [largeBorderButton, mediumBlueButton, smallButtons]).then {
            $0.axis = .vertical
            $0.spacing = 5
            $0.alignment = .center
        }

        let imageViews = UIStackView(arrangedSubviews: [circleImageView, roundedImageView]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }
        
        view.addSubview(titleView)
        view.addSubview(buttons)
        view.addSubview(imageViews)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        buttons.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        imageViews.snp.makeConstraints {
            $0.top.equalTo(buttons.snp.bottom).offset(16)
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
    
    private func fetchSupabaseSmokeTest() {
        Single.zip(
            sportsRepository.fetchFacilities(limit: 5),
            sportsRepository.searchPrograms(keyword: "탁구"),
            weatherRepository.fetchWeather(latitude: 37.5710, longitude: 127.9770)
        )
        .subscribe(
            onSuccess: { publicFacilityPage, filteredClassInformationPage, weather in
                print("공공시설 조회 성공:", publicFacilityPage.items.count)
                print("공공시설 다음 페이지 여부:", publicFacilityPage.hasNextPage)
                print("공공시설 첫 데이터:", publicFacilityPage.items.first ?? "없음")
                
                print("프로그램 목록 조회 성공:", filteredClassInformationPage.items.count)
                print("프로그램 목록 다음 페이지 여부:", filteredClassInformationPage.hasNextPage)
                print("프로그램 목록 첫 데이터:", filteredClassInformationPage.items.first ?? "없음")
                
                print("광화문 날씨:", weather)
            },
            onFailure: { error in
                print("Supabase 조회 실패:", error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
    }
}

final class TempReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        
    }
    
    struct State {}
}
