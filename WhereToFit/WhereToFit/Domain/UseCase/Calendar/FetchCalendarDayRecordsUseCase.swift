//
//  FetchCalendarDayRecordsUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

nonisolated struct CalendarDayRecords: Equatable, Sendable {
    let weightRecord: WeightRecord?
    let conditionRecord: ConditionRecord?
    let exerciseRecords: [ExerciseRecord]
}

final class FetchCalendarDayRecordsUseCase {
    private let repository: CalendarRecordRepositoryProtocol
    private let calendar: Calendar

    init(
        repository: CalendarRecordRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(date: Date) -> Single<CalendarDayRecords> {
        let recordDate = calendar.startOfDay(for: date)

        return Single.zip(
            repository.fetchWeightRecord(on: recordDate),
            repository.fetchConditionRecord(on: recordDate),
            repository.fetchExerciseRecords(on: recordDate)
        )
        .map { weightRecord, conditionRecord, exerciseRecords in
            CalendarDayRecords(
                weightRecord: weightRecord,
                conditionRecord: conditionRecord,
                exerciseRecords: exerciseRecords
            )
        }
    }
}
