//
//  MyFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit
import RxSwift

final class MyFlow: Flow {
    private let navigationController = UINavigationController()
    private let favoriteRepository = CoreDataFavoriteRepository()
    private let disposeBag = DisposeBag()
    private lazy var favoriteDetailResolver = FavoriteDetailResolver(
        favoriteRepository: favoriteRepository
    )
    private lazy var favoriteToggleService = FavoriteToggleService(repository: favoriteRepository)
    private let myReactor = MyReactor(
        fetchICloudSyncStatusUseCase: FetchICloudSyncStatusUseCase(
            service: ICloudStatusService()
        ),
        fetchUserProfileUseCase: FetchUserProfileUseCase(
            repository: CoreDataUserProfileRepository()
        ),
        fetchUserLocationsUseCase: FetchUserLocationsUseCase(
            repository: CoreDataUserLocationRepository()
        )
    )
    private lazy var myViewController = MyViewController(reactor: myReactor)
    var root: any RxFlow.Presentable { navigationController }

    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }

        switch step {
        case .myTab:
            if navigationController.viewControllers.contains(myViewController) {
                return .none
            }

            navigationController.setViewControllers([myViewController], animated: false)
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: myViewController,
                    withNextStepper: myViewController
                )
            )

        case .profileManagement:
            let vc = ProfileManagementViewController(
                reactor: ProfileManagementReactor(
                    fetchUserProfileUseCase: FetchUserProfileUseCase(
                        repository: CoreDataUserProfileRepository()
                    ),
                    upsertUserProfileUseCase: UpsertUserProfileUseCase(
                        repository: CoreDataUserProfileRepository()
                    ),
                    validatePersonalInfoUseCase: ValidateOnboardingPersonalInfoUseCase(
                        dateService: DateService()
                    )
                )
            )
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .notificationSetting:
            let vc = NotificationSettingViewController(reactor: NotificationSettingReactor())
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .favoritePrograms:
            let vc = FavoriteListViewController(
                reactor: FavoriteListReactor(
                    fetchFavoritesUseCase: FetchFavoritesUseCase(
                        repository: favoriteRepository
                    ),
                    removeFavoriteUseCase: RemoveFavoriteUseCase(
                        repository: favoriteRepository
                    )
                )
            )
            vc.favoriteItemSelected = { [weak self] item in
                self?.navigateToFavoriteDetail(item)
            }
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .registeredPrograms:
            let vc = RegisteredProgramsViewController(
                reactor: RegisteredProgramsReactor(
                    fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase(
                        repository: CoreDataRegisteredProgramRepository()
                    ),
                    removeRegisteredProgramUseCase: RemoveRegisteredProgramUseCase(
                        repository: CoreDataRegisteredProgramRepository()
                    )
                )
            )
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .exerciseResult:
            let vc = ExerciseResultViewController(
                reactor: ExerciseResultReactor(
                    fetchUserProfileUseCase: FetchUserProfileUseCase(
                        repository: CoreDataUserProfileRepository()
                    )
                )
            )
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .exerciseResultRetry:
            let userProfileRepository = CoreDataUserProfileRepository()
            let vc = OnboardingViewController(
                reactor: OnboardingReactor(
                    mode: .exerciseResultRetry,
                    dateService: DateService(),
                    addressCoordinateUseCase: AddressCoordinateUseCase(
                        repository: NaverMapSearchRepository()
                    ),
                    fetchUserProfileUseCase: FetchUserProfileUseCase(
                        repository: userProfileRepository
                    ),
                    upsertUserProfileUseCase: UpsertUserProfileUseCase(
                        repository: userProfileRepository
                    ),
                    addUserLocationUseCase: AddUserLocationUseCase(
                        repository: CoreDataUserLocationRepository()
                    ),
                    saveWeightRecordUseCase: SaveWeightRecordUseCase(
                        repository: CoreDataCalendarRecordRepository()
                    )
                )
            )
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .pageBack:
            navigationController.popViewController(animated: true)
            return .none

        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

private extension MyFlow {
    func navigateToFavoriteDetail(_ item: FavoriteListReactor.FavoriteItem) {
        favoriteDetailResolver.resolve(input: FavoriteDetailResolveInput(item: item))
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] target in
                self?.pushFavoriteDetail(target)
            })
            .disposed(by: disposeBag)
    }

    func pushFavoriteDetail(_ target: FavoriteDetailTarget) {
        let viewController = FacilityDetailViewController(
            facility: target.facility,
            relatedPrograms: target.relatedPrograms
        )
        viewController.hidesBottomBarWhenPushed = true
        viewController.favoriteButtonTapped = { [weak self] request in
            self?.handleFavoriteToggle(request)
        }
        viewController.reservationButtonTapped = { selectedFacility in
            UIApplication.shared.open(selectedFacility.reservationURL)
        }
        navigationController.pushViewController(viewController, animated: true)
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
                onNext: {
                    request.completion(true)
                },
                onError: { _ in
                    request.completion(false)
                }
            )
            .disposed(by: disposeBag)
    }
}

private extension FavoriteDetailResolveInput {
    init(item: FavoriteListReactor.FavoriteItem) {
        self.init(
            targetType: item.targetType,
            targetID: item.targetID,
            name: item.name,
            facilityLabelText: item.facilityLabelText,
            time: item.time,
            distance: item.distance,
            price: item.price,
            reservationMethodText: item.reservationMethodText,
            imageURLString: item.imageURLString,
            sportsCategoryRawValue: item.sportsCategoryRawValue
        )
    }
}
