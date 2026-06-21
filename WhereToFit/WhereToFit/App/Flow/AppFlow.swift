//
//  AppFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/19/26.
//

import UIKit
import RxFlow
import RxSwift
import ReactorKit

final class AppFlow: Flow {
    let window: UIWindow
    var root: any RxFlow.Presentable { window }

    private let dateService = DateService()

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        self.window.makeKeyAndVisible()
    }

    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }

        switch step {
        case .splash:
            return navigateToSplash()

        case .onboarding:
            return navigateToOnboarding()

        case .main:
            return navigateToMain()

        case let .alert(title, message):
            return presentAlert(title: title, message: message)

        case .updateRequired:
            return .none

        default:
            return .none
        }
    }
}

extension AppFlow {
    private func navigateToSplash() -> FlowContributors {
        let ruleRepository = SportRecommendationRuleRepository()
        let splashViewController = SplashViewController(
            reactor: SplashReactor(
                fetchUserProfileUseCase: FetchUserProfileUseCase(
                    repository: CoreDataUserProfileRepository()
                ),
                preloadSportRecommendationRulesUseCase: PreloadSportRecommendationRulesUseCase(
                    repository: ruleRepository
                )
            )
        )
        window.rootViewController = splashViewController

        return .one(
            flowContributor: .contribute(
                withNextPresentable: splashViewController,
                withNextStepper: splashViewController
            )
        )
    }

    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow(window: window, dateService: dateService)
        return .one(
            flowContributor: .contribute(
                withNextPresentable: mainFlow,
                withNextStepper: OneStepper(withSingleStep: AppStep.main))
            )
    }

//    private func navigateToUpdateRequired(message: String, storeURL: URL) -> FlowContributors {
//        guard window.rootViewController is UpdateRequiredViewController == false else {
//            return .none
//        }
//
//        let updateRequiredViewController = UpdateRequiredViewController(
//            message: message,
//            storeURL: storeURL
//        )
//
//        window.rootViewController = updateRequiredViewController
//        return .none
//    }

    private func navigateToOnboarding() -> FlowContributors {
        let userProfileRepository = CoreDataUserProfileRepository()
        let userLocationRepository = CoreDataUserLocationRepository()
        let calendarRecordRepository = CoreDataCalendarRecordRepository()
        let vc = OnboardingViewController(
            reactor: OnboardingReactor(
                dateService: dateService,
                addressCoordinateUseCase: AddressCoordinateUseCase(
                    repository: NaverMapSearchRepository()
                ),
                upsertUserProfileUseCase: UpsertUserProfileUseCase(
                    repository: userProfileRepository
                ),
                addUserLocationUseCase: AddUserLocationUseCase(
                    repository: userLocationRepository
                ),
                saveWeightRecordUseCase: SaveWeightRecordUseCase(
                    repository: calendarRecordRepository
                )
            )
        )
        window.rootViewController = vc
        return .one(
            flowContributor: .contribute(
                withNextPresentable: vc,
                withNextStepper: vc
            ))
    }

    private func presentAlert(title: String, message: String) -> FlowContributors {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))

        window.rootViewController?.present(alert, animated: true)
        return .none
    }
}
