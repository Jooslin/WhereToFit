//
//  CalendarRecordRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol CalendarRecordRepositoryProtocol {
    func fetchWeightRecord(on date: Date) -> Single<WeightRecord?>
    func fetchWeightRecords(from startDate: Date, to endDate: Date) -> Single<[WeightRecord]>
    func upsertWeightRecord(_ record: WeightRecord) -> Single<WeightRecord>

    func fetchConditionRecord(on date: Date) -> Single<ConditionRecord?>
    func fetchConditionRecords(from startDate: Date, to endDate: Date) -> Single<[ConditionRecord]>
    func upsertConditionRecord(_ record: ConditionRecord) -> Single<ConditionRecord>

    func fetchExerciseRecords(on date: Date) -> Single<[ExerciseRecord]>
    func fetchExerciseRecords(from startDate: Date, to endDate: Date) -> Single<[ExerciseRecord]>
    func saveExerciseRecord(_ record: ExerciseRecord) -> Single<ExerciseRecord>
    func saveHealthKitExerciseRecordIfNeeded(_ record: ExerciseRecord) -> Single<ExerciseRecord?>
}
