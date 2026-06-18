//
//  CoreDataCalendarRecordRepository.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation
import RxSwift

final class CoreDataCalendarRecordRepository: CalendarRecordRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func fetchWeightRecord(on date: Date) -> Single<WeightRecord?> {
        fetchFirst(
            entityName: "WeightRecordEntity",
            predicate: CoreDataDateRange.dayPredicate(key: "date", date: date),
            mapper: Self.makeWeightRecord
        )
    }

    func fetchWeightRecords(from startDate: Date, to endDate: Date) -> Single<[WeightRecord]> {
        fetchRecords(
            entityName: "WeightRecordEntity",
            predicate: NSPredicate(format: "%K >= %@ AND %K <= %@", "date", startDate as NSDate, "date", endDate as NSDate),
            mapper: Self.makeWeightRecord
        )
    }

    func upsertWeightRecord(_ record: WeightRecord) -> Single<WeightRecord> {
        upsertSingleDailyRecord(
            entityName: "WeightRecordEntity",
            date: record.date,
            apply: { Self.apply(record, to: $0) },
            result: record
        )
    }

    func fetchConditionRecord(on date: Date) -> Single<ConditionRecord?> {
        fetchFirst(
            entityName: "ConditionRecordEntity",
            predicate: CoreDataDateRange.dayPredicate(key: "date", date: date),
            mapper: Self.makeConditionRecord
        )
    }

    func fetchConditionRecords(from startDate: Date, to endDate: Date) -> Single<[ConditionRecord]> {
        fetchRecords(
            entityName: "ConditionRecordEntity",
            predicate: NSPredicate(format: "%K >= %@ AND %K <= %@", "date", startDate as NSDate, "date", endDate as NSDate),
            mapper: Self.makeConditionRecord
        )
    }

    func upsertConditionRecord(_ record: ConditionRecord) -> Single<ConditionRecord> {
        upsertSingleDailyRecord(
            entityName: "ConditionRecordEntity",
            date: record.date,
            apply: { Self.apply(record, to: $0) },
            result: record
        )
    }

    func fetchExerciseRecords(on date: Date) -> Single<[ExerciseRecord]> {
        fetchRecords(
            entityName: "ExerciseRecordEntity",
            predicate: CoreDataDateRange.dayPredicate(key: "date", date: date),
            mapper: Self.makeExerciseRecord
        )
    }

    func fetchExerciseRecords(from startDate: Date, to endDate: Date) -> Single<[ExerciseRecord]> {
        fetchRecords(
            entityName: "ExerciseRecordEntity",
            predicate: NSPredicate(format: "%K >= %@ AND %K <= %@", "date", startDate as NSDate, "date", endDate as NSDate),
            mapper: Self.makeExerciseRecord
        )
    }

    func saveExerciseRecord(_ record: ExerciseRecord) -> Single<ExerciseRecord> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try Self.fetchObject(entityName: "ExerciseRecordEntity", id: record.id, context: context)
                        ?? context.insertObject(entityName: "ExerciseRecordEntity")

                    Self.apply(record, to: object)
                    try context.save()
                    single(.success(record))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func saveHealthKitExerciseRecordIfNeeded(_ record: ExerciseRecord) -> Single<ExerciseRecord?> {
        guard record.source == .healthKit,
              let healthKitUUID = record.healthKitUUID else {
            return saveExerciseRecord(record).map(Optional.some)
        }

        return Single.create { [context] single in
            context.perform {
                do {
                    let existingObject = try context.fetchObjects(
                        entityName: "ExerciseRecordEntity",
                        predicate: NSPredicate(format: "%K == %@", "healthKitUUID", healthKitUUID as CVarArg),
                        fetchLimit: 1
                    ).first

                    guard existingObject == nil else {
                        single(.success(nil))
                        return
                    }

                    let object = try context.insertObject(entityName: "ExerciseRecordEntity")
                    Self.apply(record, to: object)
                    try context.save()
                    single(.success(record))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private func fetchRecords<T>(
        entityName: String,
        predicate: NSPredicate?,
        mapper: @escaping (NSManagedObject) -> T?
    ) -> Single<[T]> {
        Single.create { [context] single in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: entityName,
                        predicate: predicate,
                        sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)]
                    )
                    single(.success(objects.compactMap(mapper)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private func fetchFirst<T>(
        entityName: String,
        predicate: NSPredicate?,
        mapper: @escaping (NSManagedObject) -> T?
    ) -> Single<T?> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try context.fetchObjects(
                        entityName: entityName,
                        predicate: predicate,
                        sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                        fetchLimit: 1
                    ).first
                    single(.success(object.flatMap(mapper)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private func upsertSingleDailyRecord<T>(
        entityName: String,
        date: Date,
        apply: @escaping (NSManagedObject) -> Void,
        result: T
    ) -> Single<T> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try context.fetchObjects(
                        entityName: entityName,
                        predicate: CoreDataDateRange.dayPredicate(key: "date", date: date),
                        fetchLimit: 1
                    ).first ?? context.insertObject(entityName: entityName)

                    apply(object)
                    try context.save()
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private static func fetchObject(
        entityName: String,
        id: UUID,
        context: NSManagedObjectContext
    ) throws -> NSManagedObject? {
        try context.fetchObjects(
            entityName: entityName,
            predicate: NSPredicate(format: "%K == %@", "id", id as CVarArg),
            fetchLimit: 1
        ).first
    }

}

private extension CoreDataCalendarRecordRepository {
    nonisolated static func makeWeightRecord(from object: NSManagedObject) -> WeightRecord? {
        guard let id = object.uuidValue(for: "id"),
              let date = object.dateValue(for: "date"),
              let value = object.doubleValue(for: "value"),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        let source = object.stringValue(for: "sourceRawValue")
            .flatMap(RecordSource.init(rawValue:)) ?? .manual

        return WeightRecord(
            id: id,
            date: date,
            value: value,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ record: WeightRecord, to object: NSManagedObject) {
        object.setValue(record.id, forKey: "id")
        object.setValue(record.date, forKey: "date")
        object.setValue(record.value, forKey: "value")
        object.setValue(record.source.rawValue, forKey: "sourceRawValue")
        object.setValue(record.createdAt, forKey: "createdAt")
        object.setValue(record.updatedAt, forKey: "updatedAt")
    }

    nonisolated static func makeConditionRecord(from object: NSManagedObject) -> ConditionRecord? {
        guard let id = object.uuidValue(for: "id"),
              let date = object.dateValue(for: "date"),
              let conditionRawValue = object.stringValue(for: "conditionRawValue"),
              let condition = ConditionLevel(rawValue: conditionRawValue),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        return ConditionRecord(
            id: id,
            date: date,
            condition: condition,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ record: ConditionRecord, to object: NSManagedObject) {
        object.setValue(record.id, forKey: "id")
        object.setValue(record.date, forKey: "date")
        object.setValue(record.condition.rawValue, forKey: "conditionRawValue")
        object.setValue(record.createdAt, forKey: "createdAt")
        object.setValue(record.updatedAt, forKey: "updatedAt")
    }

    nonisolated static func makeExerciseRecord(from object: NSManagedObject) -> ExerciseRecord? {
        guard let id = object.uuidValue(for: "id"),
              let date = object.dateValue(for: "date"),
              let exerciseName = object.stringValue(for: "exerciseName"),
              let duration = object.doubleValue(for: "duration"),
              let sourceRawValue = object.stringValue(for: "sourceRawValue"),
              let source = RecordSource(rawValue: sourceRawValue),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        return ExerciseRecord(
            id: id,
            date: date,
            exerciseName: exerciseName,
            activityTypeRawValue: object.intValue(for: "activityTypeRawValue"),
            sportsCategoryRawValue: object.stringValue(for: "sportsCategoryRawValue"),
            duration: duration,
            calories: object.doubleValue(for: "calories"),
            source: source,
            healthKitUUID: object.uuidValue(for: "healthKitUUID"),
            startDate: object.dateValue(for: "startDate"),
            endDate: object.dateValue(for: "endDate"),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ record: ExerciseRecord, to object: NSManagedObject) {
        object.setValue(record.id, forKey: "id")
        object.setValue(record.date, forKey: "date")
        object.setValue(record.exerciseName, forKey: "exerciseName")
        object.setValue(record.activityTypeRawValue, forKey: "activityTypeRawValue")
        object.setValue(record.sportsCategoryRawValue, forKey: "sportsCategoryRawValue")
        object.setValue(record.duration, forKey: "duration")
        object.setValue(record.calories, forKey: "calories")
        object.setValue(record.source.rawValue, forKey: "sourceRawValue")
        object.setValue(record.healthKitUUID, forKey: "healthKitUUID")
        object.setValue(record.startDate, forKey: "startDate")
        object.setValue(record.endDate, forKey: "endDate")
        object.setValue(record.createdAt, forKey: "createdAt")
        object.setValue(record.updatedAt, forKey: "updatedAt")
    }
}
