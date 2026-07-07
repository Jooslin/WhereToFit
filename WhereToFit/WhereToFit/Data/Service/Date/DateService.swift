//
//  DateService.swift
//  WhereToFit
//
//  Created by 변예린 on 6/10/26.
//
import Foundation

final class DateService {
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(nowProvider: @escaping () -> Date = { Date.now }) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 2

        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func isNight() -> Bool {
        let hour = calendar.component(.hour, from: nowProvider())
        return hour >= 18 || hour < 6
    }

    // Date.now를 기준으로 해당 날짜의 시작 시간(자정)을 반환
    func today() -> Date {
        calendar.startOfDay(for: nowProvider())
    }

    func weekday(from date: Date) -> Weekday {
        Weekday(dateCompWeekday: calendar.component(.weekday, from: date))
    }

    // Date는 시/분/초를 포함하므로 같은 날짜라도 서로 다른 값일 수 있습니다.
    
    func startOfDay(_ dateComp: DateComponents) -> Date {
        calendar.startOfDay(
            for: calendar.date(from: dateComp)!
        )
    }

    func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    // 저장 전 자정 기준으로 맞추고, 오래된 날짜부터 정렬합니다.
    func startOfDay(_ dates: [Date]) -> [Date] {
        dates.map {
            startOfDay($0)
        }.sorted()
    }

    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    func date(year: Int, month: Int, day: Int) -> Date? {
        guard year > 0 else {
            return nil
        }

        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day else {
            return nil
        }

        return date
    }
}

extension DateService {
    func weeklyDate() -> [WeeklyDate] {
        let today = calendar.startOfDay(for: nowProvider())

        guard let monday = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday)!
            let day = calendar.component(.day, from: date)
            let weekday = calendar.component(.weekday, from: date)
            let weekdayText = calendar.isDate(date, inSameDayAs: today) ? "오늘" : Weekday(dateCompWeekday: weekday).title

            return WeeklyDate(
                date: date,
                weekday: Weekday(dateCompWeekday: weekday),
                weekdayString: weekdayText,
                day: day
            )
        }
    }
}

//MARK: Types
struct WeeklyDate: Hashable {
    let date: Date
    let weekday: Weekday
    let weekdayString: String
    let day: Int
}
