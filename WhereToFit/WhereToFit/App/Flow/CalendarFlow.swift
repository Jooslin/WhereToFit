//
//  CalendarFlow.swift
//  WhereToFit
//
//  Created by 변예린 on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class CalendarFlow: Flow {
    private let navigationController = UINavigationController()
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .calendarTab:
            let vc = CalendarViewController(reactor: CalendarReactor())
            navigationController.pushViewController(vc, animated: true)
            return .one(flowContributor: .contribute(withNextPresentable: vc, withNextStepper: vc))

        case .calendarWeightInput:
            presentWeightInput()
            return .none

        case .calendarConditionInput:
            presentConditionInput()
            return .none

        case .calendarExerciseRecordInput:
            presentExerciseRecordInput()
            return .none
            
        default:
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }
}

private extension CalendarFlow {
    var calendarViewController: CalendarViewController? {
        navigationController.topViewController as? CalendarViewController
    }

    func presentWeightInput() {
        guard let calendarViewController,
              let reactor = calendarViewController.reactor
        else { return }

        let viewController = WeightInputViewController(currentWeight: reactor.currentState.weight)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        viewController.onSave = { [weak reactor] weight in
            reactor?.action.onNext(.updateWeight(weight))
        }

        calendarViewController.present(viewController, animated: true)
    }

    func presentConditionInput() {
        guard let calendarViewController,
              let reactor = calendarViewController.reactor
        else { return }

        let viewController = ConditionInputViewController(currentCondition: reactor.currentState.condition)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        viewController.onSave = { [weak reactor] condition in
            reactor?.action.onNext(.updateCondition(condition))
        }

        calendarViewController.present(viewController, animated: true)
    }

    func presentExerciseRecordInput() {
        guard let calendarViewController else { return }

        let viewController = ExerciseRecordInputViewController()
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve

        calendarViewController.present(viewController, animated: true)
    }
}
