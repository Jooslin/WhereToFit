//
//  ProgramReminderTarget.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import Foundation

struct ProgramReminderTime: Hashable {
    let hour: Int
    let minute: Int

    init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        self.hour = hour
        self.minute = minute
    }

    init?(text: String?) {
        guard let text else { return nil }

        let pattern = #"(\d{1,2})(?::(\d{2}))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let hour = Int(text[hourRange]) else {
            return nil
        }

        let minute: Int
        if match.range(at: 2).location != NSNotFound,
           let minuteRange = Range(match.range(at: 2), in: text),
           let parsedMinute = Int(text[minuteRange]) {
            minute = parsedMinute
        } else {
            minute = 0
        }

        self.init(hour: hour, minute: minute)
    }

    init?(minuteOfDay: Int?) {
        guard let minuteOfDay else { return nil }

        self.init(
            hour: minuteOfDay / 60,
            minute: minuteOfDay % 60
        )
    }
}

struct ProgramReminderTarget: Hashable {
    let registeredProgramID: String
    let programName: String
    let facilityName: String?
    let days: [DayOfWeek]
    let reservationDates: [Date]
    let startTime: ProgramReminderTime

    init?(
        registeredProgramID: String,
        programName: String,
        facilityName: String?,
        days: [DayOfWeek],
        reservationDates: [Date] = [],
        startTime: ProgramReminderTime?
    ) {
        let trimmedID = registeredProgramID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProgramName = programName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedID.isEmpty == false,
              trimmedProgramName.isEmpty == false,
              days.isEmpty == false || reservationDates.isEmpty == false,
              let startTime else {
            return nil
        }

        self.registeredProgramID = trimmedID
        self.programName = trimmedProgramName
        self.facilityName = facilityName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.days = days
        self.reservationDates = reservationDates
        self.startTime = startTime
    }

    init?(program: Program, registeredProgramID: String) {
        self.init(
            registeredProgramID: registeredProgramID,
            programName: program.className ?? program.sport ?? "등록한 프로그램",
            facilityName: program.facilityName,
            days: DayOfWeek.programReminderDays(from: program.days),
            reservationDates: [],
            startTime: ProgramReminderTime(text: program.startTime)
        )
    }

    init?(registeredProgram: RegisteredProgram) {
        self.init(
            registeredProgramID: registeredProgram.id.uuidString,
            programName: registeredProgram.programName,
            facilityName: registeredProgram.facilityName,
            days: registeredProgram.isRecurring
                ? DayOfWeek.programReminderDays(from: registeredProgram.days)
                : [],
            reservationDates: registeredProgram.hasReservationDates
                ? registeredProgram.reservationDates
                : [],
            startTime: ProgramReminderTime(minuteOfDay: registeredProgram.startMinuteOfDay)
        )
    }
}

extension RegisteredProgram: RegisteredProgramReminderProviding {
    var reminderTarget: ProgramReminderTarget? {
        ProgramReminderTarget(registeredProgram: self)
    }
}

extension DayOfWeek {
    var calendarWeekday: Int {
        switch self {
        case .sunday:
            return 1
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        }
    }

    var previousDay: DayOfWeek {
        switch self {
        case .monday:
            return .sunday
        case .tuesday:
            return .monday
        case .wednesday:
            return .tuesday
        case .thursday:
            return .wednesday
        case .friday:
            return .thursday
        case .saturday:
            return .friday
        case .sunday:
            return .saturday
        }
    }

    static func programReminderDays(from rawDays: [String]) -> [DayOfWeek] {
        let joinedDays = rawDays
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        guard joinedDays.isEmpty == false else { return [] }

        if joinedDays.contains("매일") || joinedDays.contains("상시") || joinedDays.contains("전체") {
            return allCases
        }

        var parsedDays: [DayOfWeek] = []

        if joinedDays.contains("평일") {
            parsedDays.append(contentsOf: [.monday, .tuesday, .wednesday, .thursday, .friday])
        }

        if joinedDays.contains("주말") {
            parsedDays.append(contentsOf: [.saturday, .sunday])
        }

        allCases
            .filter { joinedDays.contains($0.title) }
            .forEach { day in
                if parsedDays.contains(day) == false {
                    parsedDays.append(day)
                }
            }

        allCases
            .filter { joinedDays.contains($0.rawValue) }
            .forEach { day in
                if parsedDays.contains(day) == false {
                    parsedDays.append(day)
                }
            }

        return allCases.filter { parsedDays.contains($0) }
    }
}
