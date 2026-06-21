//
//  SaveConditionRecordUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

final class SaveConditionRecordUseCase {
    private let repository: CalendarRecordRepositoryProtocol
    private let calendar: Calendar

    init(
        repository: CalendarRecordRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(date: Date, condition: ConditionLevel) -> Single<ConditionRecord> {
        let recordDate = calendar.startOfDay(for: date)
        let now = Date()

        return repository.fetchConditionRecord(on: recordDate)
            .flatMap { [repository] existingRecord in
                let record = ConditionRecord(
                    id: existingRecord?.id ?? UUID(),
                    date: recordDate,
                    condition: condition,
                    createdAt: existingRecord?.createdAt ?? now,
                    updatedAt: now
                )

                return repository.upsertConditionRecord(record)
            }
    }
}
