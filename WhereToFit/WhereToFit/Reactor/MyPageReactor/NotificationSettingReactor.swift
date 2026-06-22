//
//  NotificationSettingReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import ReactorKit
import RxSwift

final class NotificationSettingReactor: BaseReactor {
    let initialState: State
    private let settingsStore: ProgramReminderSettingsStore
    private let reminderRepository: RegisteredProgramReminderRepositoryProtocol
    private let reminderScheduler: ProgramReminderScheduler

    init(
        settingsStore: ProgramReminderSettingsStore = .shared,
        reminderRepository: RegisteredProgramReminderRepositoryProtocol = CoreDataRegisteredProgramRepository(),
        reminderScheduler: ProgramReminderScheduler = .shared
    ) {
        self.settingsStore = settingsStore
        self.reminderRepository = reminderRepository
        self.reminderScheduler = reminderScheduler
        self.initialState = State(settings: settingsStore.load())
    }

    enum Action {
        case setReservationReminderEnabled(Bool)
        case setStartReminderEnabled(Bool)
        case selectStartReminderOffset(ProgramReminderOffset)
    }

    enum Mutation {
        case setReservationReminderEnabled(Bool)
        case setStartReminderEnabled(Bool)
        case setStartReminderOffset(ProgramReminderOffset)
    }

    struct State: Equatable {
        var isReservationReminderEnabled: Bool
        var isStartReminderEnabled: Bool
        var selectedOffset: ProgramReminderOffset
        let offsetOptions = ProgramReminderOffset.allCases

        init(settings: ProgramReminderSettings) {
            self.isReservationReminderEnabled = settings.isReservationReminderEnabled
            self.isStartReminderEnabled = settings.isStartReminderEnabled
            self.selectedOffset = settings.startReminderOffset
        }
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setReservationReminderEnabled(let isEnabled):
            saveSettings(isReservationReminderEnabled: isEnabled)
            return .just(.setReservationReminderEnabled(isEnabled))

        case .setStartReminderEnabled(let isEnabled):
            saveSettings(isStartReminderEnabled: isEnabled)
            return .just(.setStartReminderEnabled(isEnabled))

        case .selectStartReminderOffset(let offset):
            saveSettings(startReminderOffset: offset)
            return .just(.setStartReminderOffset(offset))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setReservationReminderEnabled(let isEnabled):
            newState.isReservationReminderEnabled = isEnabled
        case .setStartReminderEnabled(let isEnabled):
            newState.isStartReminderEnabled = isEnabled
        case .setStartReminderOffset(let offset):
            newState.selectedOffset = offset
        }

        return newState
    }
}

private extension NotificationSettingReactor {
    func saveSettings(
        isReservationReminderEnabled: Bool? = nil,
        isStartReminderEnabled: Bool? = nil,
        startReminderOffset: ProgramReminderOffset? = nil
    ) {
        var settings = settingsStore.load()

        if let isReservationReminderEnabled {
            settings.isReservationReminderEnabled = isReservationReminderEnabled
        }

        if let isStartReminderEnabled {
            settings.isStartReminderEnabled = isStartReminderEnabled
        }

        if let startReminderOffset {
            settings.startReminderOffset = startReminderOffset
        }

        settingsStore.save(settings)
        reminderScheduler.rescheduleStartReminders(
            using: reminderRepository,
            settings: settings
        ) { _ in }
    }
}
