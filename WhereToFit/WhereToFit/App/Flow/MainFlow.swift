//
//  MainFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class MainFlow: Flow {
    private let window: UIWindow
    private let tabBarController = UITabBarController()
    
    var root: any Presentable { tabBarController }
    
    init(window: UIWindow) {
        window.rootViewController = tabBarController
        self.window = window
    }
    
    func navigate(to step: any RxFlow.Step) -> FlowContributors {
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .main:
            return navigateToMain()
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
    
    private func navigate(to viewController: UIViewController, animated: Bool) {
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
        }
    }
    
    private func present(_ viewController: UIViewController, animated: Bool) {
        tabBarController.selectedViewController?.present(viewController, animated: animated, completion: nil)
    }
    
    private func pop(animated: Bool) {
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.popViewController(animated: animated)
        } else {
            tabBarController.selectedViewController?.dismiss(animated: animated)
        }
    }
}

extension MainFlow {
    private func navigateToMain() -> FlowContributors {
        
        let homeFlow = HomeFlow()
        let mapFlow = MapFlow()
        let calendarFlow = CalendarFlow()
        let myFlow = MyFlow()
        
        Flows.use(homeFlow, mapFlow, calendarFlow, myFlow, when: .created) { home, map, calendar, my in
            home.tabBarItem = UITabBarItem(title: "홈", image: .home, selectedImage: .homeFilled)
            map.tabBarItem = UITabBarItem(title: "지도", image: .locationPin, selectedImage: .locationPinFilled)
            calendar.tabBarItem = UITabBarItem(title: "캘린더", image: .date, selectedImage: .dateFilled)
            my.tabBarItem = UITabBarItem(title: "마이", image: .home, selectedImage: .homeFilled)
            
            self.tabBarController.setViewControllers([home, map, calendar, my], animated: true)
            self.tabBarController.tabBar.tintColor = .gray800
            self.tabBarController.tabBar.unselectedItemTintColor = .gray400 // iOS26에서는 적용 안되는 것으로 확인
        }
        
        return .multiple(flowContributors: [
            .contribute(withNextPresentable: homeFlow, withNextStepper: OneStepper(withSingleStep: AppStep.homeTab)),
            .contribute(withNextPresentable: mapFlow, withNextStepper: OneStepper(withSingleStep: AppStep.mapTab)),
            .contribute(withNextPresentable: calendarFlow, withNextStepper: OneStepper(withSingleStep: AppStep.calendarTab)),
            .contribute(withNextPresentable: myFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myTab))
        ])
    }
    
    private func presentAlert(title: String, message: String) -> FlowContributors {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        present(alert, animated: true)
        return .none
    }
}
