//
//  CoreDataUserLocationRepository.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation
import RxSwift

final class CoreDataUserLocationRepository: UserLocationRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func fetchUserLocations(userProfileID: UUID) -> Single<[UserLocation]> {
        Single.create { [context] single in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "UserLocationEntity",
                        predicate: NSPredicate(format: "%K == %@", "userProfileID", userProfileID as NSUUID),
                        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
                    )
                    single(.success(objects.compactMap(Self.makeUserLocation)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func fetchSelectedUserLocation(userProfileID: UUID) -> Single<UserLocation?> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try context.fetchObjects(
                        entityName: "UserLocationEntity",
                        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                            NSPredicate(format: "%K == %@", "userProfileID", userProfileID as NSUUID),
                            NSPredicate(format: "%K == %@", "isSelected", NSNumber(value: true))
                        ]),
                        sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                        fetchLimit: 1
                    ).first
                    single(.success(object.flatMap(Self.makeUserLocation)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func saveUserLocation(_ location: UserLocation) -> Single<UserLocation> {
        Single.create { [context] single in
            context.perform {
                do {
                    if location.isSelected {
                        try Self.clearSelectedLocations(
                            userProfileID: location.userProfileID,
                            context: context,
                            exceptID: location.id
                        )
                    }

                    let object = try context.fetchObjects(
                        entityName: "UserLocationEntity",
                        predicate: NSPredicate(format: "%K == %@", "id", location.id as NSUUID),
                        fetchLimit: 1
                    ).first ?? context.insertObject(entityName: "UserLocationEntity")

                    Self.apply(location, to: object)
                    try context.save()
                    single(.success(location))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func deleteUserLocation(id: UUID) -> Completable {
        Completable.create { [context] completable in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "UserLocationEntity",
                        predicate: NSPredicate(format: "%K == %@", "id", id as NSUUID)
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

    private static func clearSelectedLocations(
        userProfileID: UUID,
        context: NSManagedObjectContext,
        exceptID: UUID
    ) throws {
        let objects = try context.fetchObjects(
            entityName: "UserLocationEntity",
            predicate: NSPredicate(
                format: "%K == %@ AND %K == %@ AND %K != %@",
                "userProfileID",
                userProfileID as NSUUID,
                "isSelected",
                NSNumber(value: true),
                "id",
                exceptID as NSUUID
            )
        )
        objects.forEach {
            $0.setValue(false, forKey: "isSelected")
        }
    }
}

private extension CoreDataUserLocationRepository {
    nonisolated static func makeUserLocation(from object: NSManagedObject) -> UserLocation? {
        guard let id = object.uuidValue(for: "id"),
              let userProfileID = object.uuidValue(for: "userProfileID"),
              let name = object.stringValue(for: "name"),
              let address = object.stringValue(for: "address"),
              let latitude = object.doubleValue(for: "latitude"),
              let longitude = object.doubleValue(for: "longitude"),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        let kind = object.stringValue(for: "kindRawValue")
            .flatMap(UserLocationKind.init(rawValue:)) ?? .custom

        return UserLocation(
            id: id,
            userProfileID: userProfileID,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            isSelected: object.boolValue(for: "isSelected") ?? false,
            kind: kind,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ location: UserLocation, to object: NSManagedObject) {
        object.setValue(location.id, forKey: "id")
        object.setValue(location.userProfileID, forKey: "userProfileID")
        object.setValue(location.name, forKey: "name")
        object.setValue(location.address, forKey: "address")
        object.setValue(location.latitude, forKey: "latitude")
        object.setValue(location.longitude, forKey: "longitude")
        object.setValue(location.isSelected, forKey: "isSelected")
        object.setValue(location.kind.rawValue, forKey: "kindRawValue")
        object.setValue(location.createdAt, forKey: "createdAt")
        object.setValue(location.updatedAt, forKey: "updatedAt")
    }
}
