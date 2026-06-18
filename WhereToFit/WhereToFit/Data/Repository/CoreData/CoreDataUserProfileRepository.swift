//
//  CoreDataUserProfileRepository.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation
import RxSwift

final class CoreDataUserProfileRepository: UserProfileRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func fetchUserProfile() -> Single<UserProfile?> {
        Single.create { [context] single in
            context.perform {
                do {
                    let objects = try context.fetchObjects(
                        entityName: "UserProfileEntity",
                        sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                        fetchLimit: 1
                    )
                    single(.success(objects.compactMap(Self.makeUserProfile).first))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func saveUserProfile(_ profile: UserProfile) -> Single<UserProfile> {
        Single.create { [context] single in
            context.perform {
                do {
                    let object = try Self.fetchProfileObject(id: profile.id, context: context)
                        ?? context.insertObject(entityName: "UserProfileEntity")

                    Self.apply(profile, to: object)
                    try context.save()
                    single(.success(profile))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private static func fetchProfileObject(
        id: UUID,
        context: NSManagedObjectContext
    ) throws -> NSManagedObject? {
        let idMatchedObject = try context.fetchObjects(
            entityName: "UserProfileEntity",
            predicate: NSPredicate(format: "%K == %@", "id", id as CVarArg),
            fetchLimit: 1
        ).first

        if let idMatchedObject {
            return idMatchedObject
        }

        return try context.fetchObjects(
            entityName: "UserProfileEntity",
            sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
            fetchLimit: 1
        ).first
    }
}

private extension CoreDataUserProfileRepository {
    nonisolated static func makeUserProfile(from object: NSManagedObject) -> UserProfile? {
        guard let id = object.uuidValue(for: "id"),
              let nickname = object.stringValue(for: "nickname"),
              let birthDate = object.dateValue(for: "birthDate"),
              let genderRawValue = object.stringValue(for: "genderRawValue"),
              let gender = UserGender(rawValue: genderRawValue),
              let createdAt = object.dateValue(for: "createdAt"),
              let updatedAt = object.dateValue(for: "updatedAt") else {
            return nil
        }

        let exerciseExperience = object.stringValue(for: "exerciseExperienceRawValue")
            .flatMap(ExerciseExperience.init(rawValue:))
        let exerciseGoals = CoreDataStringArrayCoder
            .decode(object.stringValue(for: "exerciseGoalRawValues"))
            .compactMap(ExerciseGoal.init(rawValue:))
        let discomfortBodyParts = CoreDataStringArrayCoder
            .decode(object.stringValue(for: "discomfortBodyPartRawValues"))
            .compactMap(DiscomfortBodyPart.init(rawValue:))

        return UserProfile(
            id: id,
            nickname: nickname,
            birthDate: birthDate,
            gender: gender,
            height: object.doubleValue(for: "height"),
            initialWeight: object.doubleValue(for: "initialWeight"),
            exerciseExperience: exerciseExperience,
            exerciseGoals: exerciseGoals,
            preferredSportsCategoryRawValues: CoreDataStringArrayCoder.decode(
                object.stringValue(for: "preferredSportsCategoryRawValues")
            ),
            discomfortBodyParts: discomfortBodyParts,
            usesPublicFacility: object.boolValue(for: "usesPublicFacility") ?? false,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated static func apply(_ profile: UserProfile, to object: NSManagedObject) {
        object.setValue(profile.id, forKey: "id")
        object.setValue(profile.nickname, forKey: "nickname")
        object.setValue(profile.birthDate, forKey: "birthDate")
        object.setValue(profile.gender.rawValue, forKey: "genderRawValue")
        object.setValue(profile.height, forKey: "height")
        object.setValue(profile.initialWeight, forKey: "initialWeight")
        object.setValue(profile.exerciseExperience?.rawValue, forKey: "exerciseExperienceRawValue")
        object.setValue(
            CoreDataStringArrayCoder.encode(profile.exerciseGoals.map(\.rawValue)),
            forKey: "exerciseGoalRawValues"
        )
        object.setValue(
            CoreDataStringArrayCoder.encode(profile.preferredSportsCategoryRawValues),
            forKey: "preferredSportsCategoryRawValues"
        )
        object.setValue(
            CoreDataStringArrayCoder.encode(profile.discomfortBodyParts.map(\.rawValue)),
            forKey: "discomfortBodyPartRawValues"
        )
        object.setValue(profile.usesPublicFacility, forKey: "usesPublicFacility")
        object.setValue(profile.createdAt, forKey: "createdAt")
        object.setValue(profile.updatedAt, forKey: "updatedAt")
    }
}
