//
//  SaveExerciseRecordUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

final class SaveExerciseRecordUseCase {
    struct Input {
        let date: Date
        let exerciseName: String
        let sportsCategoryRawValue: String?
        let duration: TimeInterval
        let calories: Double?
    }

    private let repository: CalendarRecordRepositoryProtocol
    private let calendar: Calendar

    init(
        repository: CalendarRecordRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(input: Input) -> Single<ExerciseRecord> {
        let recordDate = calendar.startOfDay(for: input.date)
        let now = Date()
        let record = ExerciseRecord(
            id: UUID(),
            date: recordDate,
            exerciseName: input.exerciseName,
            activityTypeRawValue: nil,
            sportsCategoryRawValue: input.sportsCategoryRawValue,
            duration: input.duration,
            calories: input.calories,
            source: .manual,
            healthKitUUID: nil,
            startDate: recordDate,
            endDate: calendar.date(byAdding: .second, value: Int(input.duration), to: recordDate),
            createdAt: now,
            updatedAt: now
        )

        return repository.saveExerciseRecord(record)
    }
}
