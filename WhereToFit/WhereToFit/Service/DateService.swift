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
            
            return WeeklyDate(weekday: weekdayText, day: day)
        }
    }
}

//MARK: Entity
struct WeeklyDate: Hashable {
    let weekday: String
    let day: Int
}

enum Weekday: Int, Hashable, CaseIterable {
    case monday = 0
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    init(dateCompWeekday: Int) {
        self = Weekday(rawValue: (dateCompWeekday + 5) % 7)!
    }
    
    var title: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }
}
