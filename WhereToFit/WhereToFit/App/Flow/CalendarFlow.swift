//
//  CalendarFlow.swift
//  WhereToFit
//
//  Created by 변예린, Yeseul Jang on 5/27/26.
//

import UIKit
import RxFlow
import ReactorKit

final class CalendarFlow: Flow {
    private let navigationController = UINavigationController()
    private let calendarRecordRepository = CoreDataCalendarRecordRepository()
    private let registeredProgramRepository = CoreDataRegisteredProgramRepository()
    private lazy var calendarReactor = CalendarReactor(
        saveWeightRecordUseCase: SaveWeightRecordUseCase(repository: calendarRecordRepository),
        saveConditionRecordUseCase: SaveConditionRecordUseCase(repository: calendarRecordRepository),
        fetchCalendarDayRecordsUseCase: FetchCalendarDayRecordsUseCase(repository: calendarRecordRepository)
    )
    private lazy var calendarViewController = CalendarViewController(reactor: calendarReactor)
    var root: any RxFlow.Presentable { navigationController }
    
    func navigate(to step: any RxFlow.Step) -> RxFlow.FlowContributors {
        // 정의한 AppStep일 때만 동작
        guard let step = step as? AppStep else {
            return .none
        }
        
        switch step {
        case .calendarTab:
            if navigationController.viewControllers.contains(calendarViewController) {
                return .none
            }

            navigationController.setViewControllers([calendarViewController], animated: false)
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: calendarViewController,
                    withNextStepper: calendarViewController
                )
            )

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
    func presentWeightInput() {
        guard navigationController.viewControllers.contains(calendarViewController),
              navigationController.presentedViewController == nil // 모달 중복 방지
        else { return }

        let viewController = WeightInputViewController(reactor: calendarReactor)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve

        navigationController.present(viewController, animated: true)
    }

    func presentConditionInput() {
        guard navigationController.viewControllers.contains(calendarViewController),
              navigationController.presentedViewController == nil
        else { return }

        let viewController = ConditionInputViewController(reactor: calendarReactor)
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve

        navigationController.present(viewController, animated: true)
    }

    func presentExerciseRecordInput() {
        guard navigationController.viewControllers.contains(calendarViewController),
              navigationController.presentedViewController == nil
        else { return }

        let viewController = ExerciseRecordInputViewController(
            reactor: ExerciseRecordInputReactor(
                selectedDate: calendarReactor.currentState.selectedDate,
                saveExerciseRecordUseCase: SaveExerciseRecordUseCase(repository: calendarRecordRepository),
                fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase(
                    repository: registeredProgramRepository
                )
            )
        )
        viewController.onSave = { [weak self] in
            self?.calendarReactor.action.onNext(.refreshSelectedDate)
        }
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve

        navigationController.present(viewController, animated: true)
    }
}
