//
//  ProgramReminderScheduler.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import Foundation
import RxSwift
import UserNotifications

enum ProgramReminderScheduleResult: Equatable {
    case scheduled(requestCount: Int)
    case disabled
    case notAuthorized
    case skippedMissingSchedule
    case failed(message: String)
}

final class ProgramReminderScheduler {
    static let shared = ProgramReminderScheduler()

    private static let identifierPrefix = "program-start"

    private let center: UNUserNotificationCenter
    private let disposeBag = DisposeBag()

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduleStartReminderIfNeeded(
        for target: ProgramReminderTarget,
        completion: @escaping (ProgramReminderScheduleResult) -> Void
    ) {
        scheduleStartReminderIfNeeded(
            for: target,
            settings: ProgramReminderSettingsStore.shared.load(),
            completion: completion
        )
    }

    func scheduleStartReminderIfNeeded(
        for target: ProgramReminderTarget,
        settings: ProgramReminderSettings,
        completion: @escaping (ProgramReminderScheduleResult) -> Void
    ) {
        guard settings.isStartReminderEnabled else {
            cancelStartReminders(for: target.registeredProgramID)
            complete(.disabled, completion)
            return
        }

        requestAuthorizationIfNeeded { [weak self] isAuthorized in
            guard let self else { return }
            guard isAuthorized else {
                self.complete(.notAuthorized, completion)
                return
            }

            self.cancelStartReminders(for: target.registeredProgramID) {
                self.scheduleStartReminders(
                    for: target,
                    offset: settings.startReminderOffset,
                    completion: completion
                )
            }
        }
    }

    func rescheduleStartReminders(
        for targets: [ProgramReminderTarget],
        settings: ProgramReminderSettings,
        completion: @escaping ([ProgramReminderScheduleResult]) -> Void
    ) {
        cancelAllStartReminders { [weak self] in
            guard let self else { return }

            guard settings.isStartReminderEnabled else {
                self.complete(Array(repeating: .disabled, count: targets.count), completion)
                return
            }

            guard targets.isEmpty == false else {
                self.complete([], completion)
                return
            }

            self.requestAuthorizationIfNeeded { isAuthorized in
                guard isAuthorized else {
                    self.complete(Array(repeating: .notAuthorized, count: targets.count), completion)
                    return
                }

                self.scheduleNextTarget(
                    ArraySlice(targets),
                    settings: settings,
                    results: [],
                    completion: completion
                )
            }
        }
    }

    func rescheduleStartReminders(
        using repository: RegisteredProgramReminderRepositoryProtocol,
        settings: ProgramReminderSettings = ProgramReminderSettingsStore.shared.load(),
        completion: @escaping ([ProgramReminderScheduleResult]) -> Void
    ) {
        repository.fetchReminderTargets()
            .subscribe(
                onSuccess: { [weak self] targets in
                    self?.rescheduleStartReminders(
                        for: targets,
                        settings: settings,
                        completion: completion
                    )
                },
                onFailure: { [weak self] error in
                    self?.complete([.failed(message: error.localizedDescription)], completion)
                }
            )
            .disposed(by: disposeBag)
    }

    func cancelStartReminders(for registeredProgramID: String) {
        cancelStartReminders(for: registeredProgramID, completion: nil)
    }

    func cancelStartReminders(for registeredProgramID: String, completion: (() -> Void)?) {
        let identifierPrefix = notificationIdentifierPrefix(registeredProgramID: registeredProgramID)
        removeStartReminders(matching: { $0.hasPrefix(identifierPrefix) }, completion: completion)
    }

    func cancelStartReminders(for target: ProgramReminderTarget) {
        let identifiers = notificationIdentifiers(for: target)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelAllStartReminders(completion: (() -> Void)? = nil) {
        removeStartReminders(
            matching: { $0.hasPrefix(Self.identifierPrefix + "-") },
            completion: completion
        )
    }
}

private extension ProgramReminderScheduler {
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.complete(true, completion)
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { isGranted, _ in
                    self.complete(isGranted, completion)
                }
            case .denied:
                self.complete(false, completion)
            @unknown default:
                self.complete(false, completion)
            }
        }
    }

    func scheduleStartReminders(
        for target: ProgramReminderTarget,
        offset: ProgramReminderOffset,
        completion: @escaping (ProgramReminderScheduleResult) -> Void
    ) {
        guard target.days.isEmpty == false || target.reservationDates.isEmpty == false else {
            complete(.skippedMissingSchedule, completion)
            return
        }

        let recurringRequests = target.days.map { day in
            makeNotificationRequest(for: target, day: day, offset: offset)
        }
        let recurringDays = Set(target.days)
        let dateRequests = target.reservationDates
            .filter { shouldScheduleReservationDate($0, recurringDays: recurringDays) }
            .compactMap { date in
                makeNotificationRequest(for: target, reservationDate: date, offset: offset)
            }
        let requests = recurringRequests + dateRequests

        guard requests.isEmpty == false else {
            complete(.skippedMissingSchedule, completion)
            return
        }

        addNextRequest(ArraySlice(requests), scheduledCount: 0, completion: completion)
    }

    func addNextRequest(
        _ requests: ArraySlice<UNNotificationRequest>,
        scheduledCount: Int,
        completion: @escaping (ProgramReminderScheduleResult) -> Void
    ) {
        guard let request = requests.first else {
            complete(.scheduled(requestCount: scheduledCount), completion)
            return
        }

        center.add(request) { [weak self] error in
            guard let self else { return }

            if let error {
                self.complete(.failed(message: error.localizedDescription), completion)
            } else {
                self.addNextRequest(
                    requests.dropFirst(),
                    scheduledCount: scheduledCount + 1,
                    completion: completion
                )
            }
        }
    }

    func scheduleNextTarget(
        _ targets: ArraySlice<ProgramReminderTarget>,
        settings: ProgramReminderSettings,
        results: [ProgramReminderScheduleResult],
        completion: @escaping ([ProgramReminderScheduleResult]) -> Void
    ) {
        guard let target = targets.first else {
            complete(results, completion)
            return
        }

        scheduleStartReminders(for: target, offset: settings.startReminderOffset) { [weak self] result in
            guard let self else { return }

            self.scheduleNextTarget(
                targets.dropFirst(),
                settings: settings,
                results: results + [result],
                completion: completion
            )
        }
    }

    func makeNotificationRequest(
        for target: ProgramReminderTarget,
        day: Weekday,
        offset: ProgramReminderOffset
    ) -> UNNotificationRequest {
        let schedule = reminderSchedule(
            day: day,
            startTime: target.startTime,
            offsetMinutes: offset.rawValue
        )

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)
        dateComponents.timeZone = .current
        dateComponents.weekday = schedule.day.calendarWeekday
        dateComponents.hour = schedule.hour
        dateComponents.minute = schedule.minute

        return UNNotificationRequest(
            identifier: notificationIdentifier(
                registeredProgramID: target.registeredProgramID,
                day: day,
                offset: offset
            ),
            content: notificationContent(for: target, offset: offset),
            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        )
    }

    func makeNotificationRequest(
        for target: ProgramReminderTarget,
        reservationDate: Date,
        offset: ProgramReminderOffset
    ) -> UNNotificationRequest? {
        guard let reminderDate = reminderDate(
            reservationDate: reservationDate,
            startTime: target.startTime,
            offsetMinutes: offset.rawValue
        ),
              reminderDate > Date() else {
            return nil
        }

        let calendar = gregorianCalendar()
        var dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        dateComponents.calendar = calendar
        dateComponents.timeZone = .current

        return UNNotificationRequest(
            identifier: notificationIdentifier(
                registeredProgramID: target.registeredProgramID,
                reservationDate: reservationDate,
                offset: offset
            ),
            content: notificationContent(for: target, offset: offset),
            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        )
    }

    func reminderSchedule(
        day: Weekday,
        startTime: ProgramReminderTime,
        offsetMinutes: Int
    ) -> (day: Weekday, hour: Int, minute: Int) {
        let startTotalMinutes = startTime.hour * 60 + startTime.minute
        let reminderTotalMinutes = startTotalMinutes - offsetMinutes

        if reminderTotalMinutes >= 0 {
            return (
                day: day,
                hour: reminderTotalMinutes / 60,
                minute: reminderTotalMinutes % 60
            )
        }

        let adjustedMinutes = reminderTotalMinutes + 24 * 60
        return (
            day: day.previousDay,
            hour: adjustedMinutes / 60,
            minute: adjustedMinutes % 60
        )
    }

    func notificationBody(for target: ProgramReminderTarget, offset: ProgramReminderOffset) -> String {
        let offsetText = offset.title.replacingOccurrences(of: "전", with: "후")

        if let facilityName = target.facilityName,
           facilityName.isEmpty == false {
            return "\(facilityName) \(target.programName) 프로그램이 \(offsetText)에 시작돼요."
        }

        return "\(target.programName)이 \(offsetText)에 시작돼요."
    }

    func notificationContent(for target: ProgramReminderTarget, offset: ProgramReminderOffset) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "곧 프로그램이 시작돼요"
        content.body = notificationBody(for: target, offset: offset)
        content.sound = .default
        content.userInfo = [
            "registeredProgramID": target.registeredProgramID,
            "programName": target.programName
        ]
        return content
    }

    func removeStartReminders(
        matching shouldRemove: @escaping (String) -> Bool,
        completion: (() -> Void)?
    ) {
        let group = DispatchGroup()

        group.enter()
        center.getPendingNotificationRequests { [weak self] requests in
            let identifiers = requests.map(\.identifier).filter(shouldRemove)
            self?.center.removePendingNotificationRequests(withIdentifiers: identifiers)
            group.leave()
        }

        group.enter()
        center.getDeliveredNotifications { [weak self] notifications in
            let identifiers = notifications.map(\.request.identifier).filter(shouldRemove)
            self?.center.removeDeliveredNotifications(withIdentifiers: identifiers)
            group.leave()
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    func notificationIdentifierPrefix(registeredProgramID: String) -> String {
        "\(Self.identifierPrefix)-\(registeredProgramID)-"
    }

    func notificationIdentifier(
        registeredProgramID: String,
        day: Weekday,
        offset: ProgramReminderOffset
    ) -> String {
        "\(Self.identifierPrefix)-\(registeredProgramID)-\(day.rawValue)-\(offset.rawValue)"
    }

    func notificationIdentifier(
        registeredProgramID: String,
        reservationDate: Date,
        offset: ProgramReminderOffset
    ) -> String {
        "\(Self.identifierPrefix)-\(registeredProgramID)-date-\(dateIdentifier(for: reservationDate))-\(offset.rawValue)"
    }

    func notificationIdentifiers(for target: ProgramReminderTarget) -> [String] {
        ProgramReminderOffset.allCases.flatMap { offset in
            let dayIdentifiers = Weekday.allCases.map { day in
                notificationIdentifier(
                    registeredProgramID: target.registeredProgramID,
                    day: day,
                    offset: offset
                )
            }
            let dateIdentifiers = target.reservationDates.map { date in
                notificationIdentifier(
                    registeredProgramID: target.registeredProgramID,
                    reservationDate: date,
                    offset: offset
                )
            }

            return dayIdentifiers + dateIdentifiers
        }
    }

    func reminderDate(
        reservationDate: Date,
        startTime: ProgramReminderTime,
        offsetMinutes: Int
    ) -> Date? {
        let calendar = gregorianCalendar()
        let startOfDay = calendar.startOfDay(for: reservationDate)
        let startDate = calendar.date(
            byAdding: .minute,
            value: startTime.hour * 60 + startTime.minute,
            to: startOfDay
        )

        return startDate.flatMap {
            calendar.date(byAdding: .minute, value: -offsetMinutes, to: $0)
        }
    }

    func shouldScheduleReservationDate(_ date: Date, recurringDays: Set<Weekday>) -> Bool {
        guard recurringDays.isEmpty == false,
              let reservationDay = weekday(for: date) else {
            return true
        }

        return recurringDays.contains(reservationDay) == false
    }

    func weekday(for date: Date) -> Weekday? {
        let weekday = gregorianCalendar().component(.weekday, from: date)
        return Weekday.allCases.first { $0.calendarWeekday == weekday }
    }

    func dateIdentifier(for date: Date) -> String {
        let components = gregorianCalendar().dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    func gregorianCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    func complete<T>(_ value: T, _ completion: @escaping (T) -> Void) {
        DispatchQueue.main.async {
            completion(value)
        }
    }
}
