//
//  AppFlow.swift
//  Gymap
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
            //TODO: 추후 수정 필요
        case .splash:
            let vc = TempViewController(reactor: TempReactor())
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: vc,
                    withNextStepper: vc
                ))

        case .main:
            return .none

        case let .updateRequired(message, storeURL):
            return .none
            
        default:
            return .none
        }
    }
}

extension AppFlow {
//    private func navigateToSplash() -> FlowContributors {
//        let splashViewController = SplashViewController()
//        window.rootViewController = splashViewController
//        
//        return .one(
//            flowContributor: .contribute(
//                withNextPresentable: splashViewController,
//                withNextStepper: splashViewController
//            )
//        )
//    }
    
//    private func navigateToMain() -> FlowContributors {
//        let mainFlow = MainFlow(window: window)
//        return .one(
//            flowContributor: .contribute(
//                withNextPresentable: mainFlow,
//                withNextStepper: OneStepper(withSingleStep: AppStep.main))
//            )
//    }

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
}
