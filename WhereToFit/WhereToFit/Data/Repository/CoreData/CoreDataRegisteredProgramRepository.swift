//
//  CoreDataRegisteredProgramRepository.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation
import RxSwift

final class CoreDataRegisteredProgramRepository: RegisteredProgramRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func fetchRegisteredPrograms() -> Single<[RegisteredProgram]> {
        Single.create { [context] single in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "RegisteredProgramEntity",
                        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
                    )
                    single(.success(objects.compactMap(Self.makeRegisteredProgram)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func saveRegisteredProgram(_ program: RegisteredProgram) -> Single<RegisteredProgram> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try context.fetchObjects(
                        entityName: "RegisteredProgramEntity",
                        predicate: NSPredicate(format: "%K == %@", "id", program.id as CVarArg),
                        fetchLimit: 1
                    ).first ?? context.insertObject(entityName: "RegisteredProgramEntity")

                    Self.apply(program, to: object)
                    try context.save()
                    single(.success(program))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func deleteRegisteredProgram(id: UUID) -> Completable {
        Completable.create { [context] completable in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "RegisteredProgramEntity",
                        predicate: NSPredicate(format: "%K == %@", "id", id as CVarArg)
                    )
                    objects.forEach(context.delete)
                    try context.save()
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }

            return Disposables.create()
        }
    }
}

private extension CoreDataRegisteredProgramRepository {
    nonisolated static func makeRegisteredProgram(from object: NSManagedObject) -> RegisteredProgram? {
        guard let id = object.uuidValue(for: "id"),
              let programName = object.stringValue(for: "programName"),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        return RegisteredProgram(
            id: id,
            programID: object.intValue(for: "programID"),
            facilityID: object.stringValue(for: "facilityID"),
            programName: programName,
            facilityName: object.stringValue(for: "facilityName"),
            sportsCategoryRawValue: object.stringValue(for: "sportsCategoryRawValue"),
            days: CoreDataStringArrayCoder.decode(object.stringValue(for: "daysRawValue")),
            startTime: object.stringValue(for: "startTime"),
            endTime: object.stringValue(for: "endTime"),
            reservationMethodRawValues: CoreDataStringArrayCoder.decode(
                object.stringValue(for: "reservationMethodsRawValue")
            ),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ program: RegisteredProgram, to object: NSManagedObject) {
        object.setValue(program.id, forKey: "id")
        object.setValue(program.programID, forKey: "programID")
        object.setValue(program.facilityID, forKey: "facilityID")
        object.setValue(program.programName, forKey: "programName")
        object.setValue(program.facilityName, forKey: "facilityName")
        object.setValue(program.sportsCategoryRawValue, forKey: "sportsCategoryRawValue")
        object.setValue(CoreDataStringArrayCoder.encode(program.days), forKey: "daysRawValue")
        object.setValue(program.startTime, forKey: "startTime")
        object.setValue(program.endTime, forKey: "endTime")
        object.setValue(
            CoreDataStringArrayCoder.encode(program.reservationMethodRawValues),
            forKey: "reservationMethodsRawValue"
        )
        object.setValue(program.createdAt, forKey: "createdAt")
        object.setValue(program.updatedAt, forKey: "updatedAt")
    }
}
