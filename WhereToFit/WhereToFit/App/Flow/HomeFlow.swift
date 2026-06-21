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
    private let userStore: UserStoreProtocol
    
    private lazy var locationReactor = LocationReactor(userStore: userStore)
    
    init(userStore: UserStoreProtocol,
         dateService: DateService,
         weatherRepository: WeatherRepositoryProtocol,
         sportsRepository: SportsRepositoryProtocol
    ) {
        self.userStore = userStore
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
            let vc = HomeViewController(
                reactor: HomeReactor(
                    userStore: userStore,
                    dateService: dateService,
                    weatherRepository: weatherRepository,
                    sportsRepository: sportsRepository
                ))
            navigationController.pushViewController(vc, animated: true)
            
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .locationSetting:
            let vc = LocationViewController(reactor: locationReactor)
            navigationController.pushViewController(vc, animated: true)
            
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .locationEdit:
            let vc = LocationEditViewController(reactor: locationReactor)
            navigationController.pushViewController(vc, animated: true)
            
            return .one(flowContributor:
                    .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .locationDetail(let mode):
            let reactor = switch mode {
            case .create:
                LocationDetailReactor(userStore: userStore, location: nil)
            case .edit(let location):
                LocationDetailReactor(userStore: userStore, location: location)
            }
            let vc = LocationDetailViewController(reactor: reactor)
            navigationController.pushViewController(vc, animated: true)
            
            return .one(flowContributor:
                    .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .programRegistration:
            let vc = ProgramRegisterViewController(reactor: ProgramRegisterReactor())
            navigationController.pushViewController(vc, animated: true)
            
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .facilitySearch:
            let vc = FacilitySearchViewController(
                reactor: FacilitySearchReactor(
                    userStore: userStore,
                    fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase(
                        repository: SportsFacilityRepository()
                    )
                )
            )
            vc.onSelectFacility = { [weak self] id, name in
                self?.sendToProgramRegister(.selectFacility(id: id, name: name))
            }
            
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
            
        case .sportsCategorySelection:
            let vc = MapFilterViewController(
                filter: .empty,
                mode: .category,
                categorySelectionBehavior: .single
            )
            vc.singleCategorySelected = { [weak self] category in
                self?.sendToProgramRegister(.selectSportsCategory(
                    displayName: category.title,
                    category: SportsCategory(sport: category.title)
                ))
            }
            
            navigationController.present(vc, animated: true)
            return .none
            
        case .selectDate:
            let vc = ProgramDateViewController(reactor: ProgramDateReactor(dateService: dateService))
            vc.onSelectDate = { [weak self] dates in
                self?.sendToProgramRegister(.selectDates(dates))
            }
            
            vc.modalPresentationStyle = .pageSheet
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            
            navigationController.present(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

extension HomeFlow {
    private func sendToProgramRegister(_ action: ProgramRegisterReactor.Action) {
        let programRegisterVC = navigationController.viewControllers
            .compactMap { $0 as? ProgramRegisterViewController }
            .last
        
        programRegisterVC?.reactor?.action.onNext(action)
    }
}
