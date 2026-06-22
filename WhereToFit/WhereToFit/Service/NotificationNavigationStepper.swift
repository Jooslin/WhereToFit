//
//  NotificationNavigationStepper.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation
import RxFlow
import RxRelay
import UserNotifications

final class NotificationNavigationStepper: Stepper {
    static let shared = NotificationNavigationStepper()

    let steps = PublishRelay<Step>()

    private let programNotificationPrefix = "program-start-"
    private var hasPendingRegisteredProgramsNavigation = false

    private init() {}

    func routeToRegisteredProgramsIfProgramNotification(_ notification: UNNotification) {
        guard isProgramNotification(identifier: notification.request.identifier) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.hasPendingRegisteredProgramsNavigation = true
            self?.emitPendingNavigationIfNeeded()
        }
    }

    func emitPendingNavigationIfNeeded() {
        guard hasPendingRegisteredProgramsNavigation else {
            return
        }

        hasPendingRegisteredProgramsNavigation = false
        steps.accept(AppStep.registeredPrograms)
    }

    func isProgramNotification(identifier: String) -> Bool {
        identifier.hasPrefix(programNotificationPrefix)
    }
}
