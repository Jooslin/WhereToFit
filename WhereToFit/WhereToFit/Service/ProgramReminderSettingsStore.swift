//
//  ProgramReminderSettingsStore.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import Foundation

enum ProgramReminderOffset: Int, CaseIterable, Equatable {
    case thirtyMinutes = 30
    case oneHour = 60

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "30분 전"
        case .oneHour:
            return "1시간 전"
        }
    }
}

struct ProgramReminderSettings: Equatable {
    var isReservationReminderEnabled: Bool
    var isStartReminderEnabled: Bool
    var startReminderOffset: ProgramReminderOffset

    static let `default` = ProgramReminderSettings(
        isReservationReminderEnabled: false,
        isStartReminderEnabled: true,
        startReminderOffset: .thirtyMinutes
    )
}

final class ProgramReminderSettingsStore {
    static let shared = ProgramReminderSettingsStore()

    private enum Key {
        static let isReservationReminderEnabled = "programReminder.isReservationReminderEnabled"
        static let isStartReminderEnabled = "programReminder.isStartReminderEnabled"
        static let startReminderOffsetMinutes = "programReminder.startReminderOffsetMinutes"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> ProgramReminderSettings {
        let defaultSettings = ProgramReminderSettings.default

        let offsetMinutes = userDefaults.object(forKey: Key.startReminderOffsetMinutes) as? Int
        let offset = offsetMinutes
            .flatMap(ProgramReminderOffset.init(rawValue:))
            ?? defaultSettings.startReminderOffset

        return ProgramReminderSettings(
            isReservationReminderEnabled: bool(forKey: Key.isReservationReminderEnabled, defaultValue: defaultSettings.isReservationReminderEnabled),
            isStartReminderEnabled: bool(forKey: Key.isStartReminderEnabled, defaultValue: defaultSettings.isStartReminderEnabled),
            startReminderOffset: offset
        )
    }

    func save(_ settings: ProgramReminderSettings) {
        userDefaults.set(settings.isReservationReminderEnabled, forKey: Key.isReservationReminderEnabled)
        userDefaults.set(settings.isStartReminderEnabled, forKey: Key.isStartReminderEnabled)
        userDefaults.set(settings.startReminderOffset.rawValue, forKey: Key.startReminderOffsetMinutes)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard userDefaults.object(forKey: key) != nil else { return defaultValue }
        return userDefaults.bool(forKey: key)
    }
}
