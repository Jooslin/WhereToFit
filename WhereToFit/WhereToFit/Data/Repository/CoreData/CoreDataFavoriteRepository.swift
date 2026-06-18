//
//  CoreDataFavoriteRepository.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation
import RxSwift

final class CoreDataFavoriteRepository: FavoriteRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func fetchFavorites(userProfileID: UUID) -> Single<[Favorite]> {
        fetchFavorites(predicate: NSPredicate(format: "%K == %@", "userProfileID", userProfileID as CVarArg))
    }

    func fetchFavorites(userProfileID: UUID, targetType: FavoriteTargetType) -> Single<[Favorite]> {
        fetchFavorites(
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "%K == %@", "userProfileID", userProfileID as CVarArg),
                NSPredicate(format: "%K == %@", "targetTypeRawValue", targetType.rawValue)
            ])
        )
    }

    func saveFavorite(_ favorite: Favorite) -> Single<Favorite> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try Self.fetchFavoriteObject(
                        userProfileID: favorite.userProfileID,
                        targetType: favorite.targetType,
                        targetID: favorite.targetID,
                        context: context
                    ) ?? context.insertObject(entityName: "FavoriteEntity")

                    Self.apply(favorite, to: object)
                    try context.save()
                    single(.success(favorite))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func deleteFavorite(userProfileID: UUID, targetType: FavoriteTargetType, targetID: String) -> Completable {
        Completable.create { [context] completable in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "FavoriteEntity",
                        predicate: Self.makeTargetPredicate(userProfileID: userProfileID, targetType: targetType, targetID: targetID)
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

    private func fetchFavorites(predicate: NSPredicate?) -> Single<[Favorite]> {
        Single.create { [context] single in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "FavoriteEntity",
                        predicate: predicate,
                        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
                    )
                    single(.success(objects.compactMap(Self.makeFavorite)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private static func fetchFavoriteObject(
        userProfileID: UUID,
        targetType: FavoriteTargetType,
        targetID: String,
        context: NSManagedObjectContext
    ) throws -> NSManagedObject? {
        try context.fetchObjects(
            entityName: "FavoriteEntity",
            predicate: makeTargetPredicate(userProfileID: userProfileID, targetType: targetType, targetID: targetID),
            fetchLimit: 1
        ).first
    }

    private nonisolated static func makeTargetPredicate(
        userProfileID: UUID,
        targetType: FavoriteTargetType,
        targetID: String
    ) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@ AND %K == %@",
            "userProfileID",
            userProfileID as CVarArg,
            "targetTypeRawValue",
            targetType.rawValue,
            "targetID",
            targetID
        )
    }
}

private extension CoreDataFavoriteRepository {
    nonisolated static func makeFavorite(from object: NSManagedObject) -> Favorite? {
        guard let id = object.uuidValue(for: "id"),
              let userProfileID = object.uuidValue(for: "userProfileID"),
              let targetTypeRawValue = object.stringValue(for: "targetTypeRawValue"),
              let targetType = FavoriteTargetType(rawValue: targetTypeRawValue),
              let targetID = object.stringValue(for: "targetID"),
              let title = object.stringValue(for: "title"),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        return Favorite(
            id: id,
            userProfileID: userProfileID,
            targetType: targetType,
            targetID: targetID,
            title: title,
            subtitle: object.stringValue(for: "subtitle"),
            sportsCategoryRawValue: object.stringValue(for: "sportsCategoryRawValue"),
            snapshotJSON: object.stringValue(for: "snapshotJSON"),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ favorite: Favorite, to object: NSManagedObject) {
        object.setValue(favorite.id, forKey: "id")
        object.setValue(favorite.userProfileID, forKey: "userProfileID")
        object.setValue(favorite.targetType.rawValue, forKey: "targetTypeRawValue")
        object.setValue(favorite.targetID, forKey: "targetID")
        object.setValue(favorite.title, forKey: "title")
        object.setValue(favorite.subtitle, forKey: "subtitle")
        object.setValue(favorite.sportsCategoryRawValue, forKey: "sportsCategoryRawValue")
        object.setValue(favorite.snapshotJSON, forKey: "snapshotJSON")
        object.setValue(favorite.createdAt, forKey: "createdAt")
        object.setValue(favorite.updatedAt, forKey: "updatedAt")
    }
}
