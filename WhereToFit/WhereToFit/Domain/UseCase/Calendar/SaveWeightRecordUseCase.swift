//
//  SaveWeightRecordUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

final class SaveWeightRecordUseCase {
    private let repository: CalendarRecordRepositoryProtocol
    private let calendar: Calendar

    init(
        repository: CalendarRecordRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(date: Date, value: Double) -> Single<WeightRecord> {
        let recordDate = calendar.startOfDay(for: date)
        let now = Date()

        return repository.fetchWeightRecord(on: recordDate)
            .flatMap { [repository] existingRecord in
                let record = WeightRecord(
                    id: existingRecord?.id ?? UUID(),
                    date: recordDate,
                    value: value,
                    source: .manual,
                    createdAt: existingRecord?.createdAt ?? now,
                    updatedAt: now
                )

                return repository.upsertWeightRecord(record)
            }
    }
}
