//
//  RemoveRegisteredProgramUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/20/26.
//

import Foundation
import RxSwift

final class RemoveRegisteredProgramUseCase {
    private let repository: RegisteredProgramRepositoryProtocol
    private let reminderScheduler: ProgramReminderScheduler

    init(
        repository: RegisteredProgramRepositoryProtocol,
        reminderScheduler: ProgramReminderScheduler = .shared
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
    }

    func execute(id: UUID) -> Completable {
        repository.deleteRegisteredProgram(id: id)
            .andThen(cancelStartReminders(for: id))
    }

    private func cancelStartReminders(for id: UUID) -> Completable {
        Completable.create { [reminderScheduler] completable in
            reminderScheduler.cancelStartReminders(for: id.uuidString) {
                completable(.completed)
            }

            return Disposables.create()
        }
    }
}
