//
//  FetchReportRecordsUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

nonisolated struct ReportRecords: Equatable, Sendable {
    let weightRecords: [WeightRecord]
    let exerciseRecords: [ExerciseRecord]
    let conditionRecords: [ConditionRecord]
}

final class FetchReportRecordsUseCase {
    private let repository: CalendarRecordRepositoryProtocol
    private let calendar: Calendar

    init(
        repository: CalendarRecordRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(today: Date = Date()) -> Single<ReportRecords> {
        let endDate = calendar.startOfDay(for: today)
        let weightStartDate = calendar.date(byAdding: .day, value: -29, to: endDate) ?? endDate
        let weeklyStartDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate

        return Single.zip(
            repository.fetchWeightRecords(from: weightStartDate, to: endDate),
            repository.fetchExerciseRecords(from: weeklyStartDate, to: endDate),
            repository.fetchConditionRecords(from: weeklyStartDate, to: endDate)
        )
        .map { weightRecords, exerciseRecords, conditionRecords in
            ReportRecords(
                weightRecords: weightRecords,
                exerciseRecords: exerciseRecords,
                conditionRecords: conditionRecords
            )
        }
    }
}
