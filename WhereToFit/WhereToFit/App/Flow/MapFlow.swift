//
//  MapFlow.swift
//  WhereToFit
//
//  Created by 변예린, Yeseul Jang on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit
import RxSwift

final class MapFlow: Flow {
    private let navigationController = UINavigationController()
    private let favoriteRepository = CoreDataFavoriteRepository()
    private let disposeBag = DisposeBag()
    private var favoriteChangeObserver: NSObjectProtocol?
    private lazy var mapReactor = MapReactor(
        fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase(
            repository: SportsFacilityRepository()
        ),
        fetchFavoritesUseCase: FetchFavoritesUseCase(
            repository: favoriteRepository
        )
    )
    private lazy var favoriteToggleService = FavoriteToggleService(repository: favoriteRepository)
    private let searchMapSuggestionsUseCase = SearchMapSuggestionsUseCase(
        repository: NaverMapSearchRepository()
    )

    var root: any RxFlow.Presentable { navigationController }

    init() {
        observeFavoriteChanges()
    }

    deinit {
        if let favoriteChangeObserver {
            NotificationCenter.default.removeObserver(favoriteChangeObserver)
        }
    }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
            // 지도 탭 첫 화면
        case .mapTab:
            let vc = MapViewController(
                reactor: mapReactor,
                searchMapSuggestionsUseCase: searchMapSuggestionsUseCase
            )
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

            // 지도 탭 필터링 화면
        case let .mapFilter(filter, priceSamples, mode):
            let vc = MapFilterViewController(filter: filter, priceSamples: priceSamples, mode: mode)
            vc.applyButtonTapped = { [weak self] filter in
                self?.mapReactor.action.onNext(.applyFilter(filter))
            }
            navigationController.present(vc, animated: true)
            return .none

            // 지도 탭 시설 상세 화면
        case let .mapFacilityDetail(facility, relatedPrograms):
            let vc = FacilityDetailViewController(facility: facility, relatedPrograms: relatedPrograms)
                // 찜 버튼 클릭
            vc.favoriteButtonTapped = { [weak self] request in
                self?.handleFavoriteToggle(request)
            }
                // 예약 버튼 클릭
            vc.reservationButtonTapped = { [weak self] selectedFacility in
                self?.mapReactor.action.onNext(.tapReservation(selectedFacility.id))
            }
            navigationController.pushViewController(vc, animated: true)
            return .none
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

private extension MapFlow {
    func observeFavoriteChanges() {
        favoriteChangeObserver = NotificationCenter.default.addObserver(
            forName: FavoriteChangeNotifier.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let change = FavoriteChangeNotifier.change(from: notification) else { return }
            self?.mapReactor.action.onNext(.setFavorite(change.targetKey, change.isFavorite))
        }
    }

    func handleFavoriteToggle(_ request: FacilityDetailFavoriteRequest) {
        favoriteToggleService
            .setFavorite(
                targetKey: request.targetKey,
                facility: request.facility,
                isSelected: request.isSelected
            )
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    guard let self else { return }
                    self.mapReactor.action.onNext(.setFavorite(request.targetKey, request.isSelected))
                    request.completion(true)
                },
                onError: { _ in
                    request.completion(false)
                }
            )
            .disposed(by: disposeBag)
    }
}
