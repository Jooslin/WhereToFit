//
//  MyFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class MyFlow: Flow {
    private let navigationController = UINavigationController()
    var root: any RxFlow.Presentable { navigationController }

    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }

        switch step {
        case .myTab:
            let vc = MyViewController(reactor: MyReactor())
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .profileManagement:
            let vc = ProfileManagementViewController(reactor: ProfileManagementReactor())
            vc.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .notificationSetting:
            let vc = NotificationSettingViewController(reactor: NotificationSettingReactor())
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
