//
//  MapFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class MapFlow: Flow {
    private let navigationController = UINavigationController()
    private let mapReactor = MapReactor(
        fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase(
            repository: MockFacilityRepository()
        )
    )

    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
            // 지도 탭 첫 화면
        case .mapTab:
            let vc = MapViewController(reactor: mapReactor)
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

            // 지도 탭 필터링 화면
        case let .mapFilter(filter):
            let vc = MapFilterViewController(filter: filter)
            vc.applyButtonTapped = { [weak self] filter in
                self?.mapReactor.action.onNext(.applyFilter(filter))
            }
            navigationController.present(vc, animated: true)
            return .none

            // 지도 탭 시설 상세 화면
        case let .mapFacilityDetail(facility):
            let vc = FacilityDetailViewController(facility: facility)
                // 찜 버튼 클릭
            vc.favoriteButtonTapped = { [weak self] in
                self?.mapReactor.action.onNext(.toggleFavorite(facility.id))
            }
                // 예약 버튼 클릭
            vc.reservationButtonTapped = { [weak self] in
                self?.mapReactor.action.onNext(.tapReservation(facility.id))
            }
            navigationController.present(vc, animated: true)
            return .none
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}
