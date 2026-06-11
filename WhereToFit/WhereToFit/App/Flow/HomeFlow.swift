//
//  HomeFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class HomeFlow: Flow {
    private let navigationController = UINavigationController()
    var root: any RxFlow.Presentable { navigationController }
    
    private let dateService: DateService
    private let weatherRepository: WeatherRepositoryProtocol
    private let sportsRepository: SportsRepositoryProtocol
    
    init(dateService: DateService, weatherRepository: WeatherRepositoryProtocol, sportsRepository: SportsRepositoryProtocol) {
        self.dateService = dateService
        self.weatherRepository = weatherRepository
        self.sportsRepository = sportsRepository
    }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .homeTab:
            let vc = HomeViewController(reactor: HomeReactor(dateService: dateService, repository: weatherRepository))
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
