//
//  DateService.swift
//  WhereToFit
//
//  Created by 변예린 on 6/10/26.
//
import Foundation

final class DateService {
    private let calendar: Calendar
    private let today: Date
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    
    init(today: Date = Date.now) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 2
        
        self.calendar = calendar
        self.today = calendar.startOfDay(for: today)
    }
    
    func weeklyDate() -> [WeeklyDate] {
        guard let monday = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday)!
            let day = calendar.component(.day, from: date)
            let weekday = calendar.component(.weekday, from: date)
            let weekdayText = calendar.isDate(date, inSameDayAs: today) ? "오늘" : weekdaySymbols[weekday - 1]
            
            return WeeklyDate(weekday: weekdayText, day: day)
        }
    }
}

//MARK: Entity
struct WeeklyDate: Hashable {
    let weekday: String
    let day: Int
}
