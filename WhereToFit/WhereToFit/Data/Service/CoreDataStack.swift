//
//  CoreDataStack.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(
        modelName: String = "WhereToFit",
        inMemory: Bool = false
    ) {
        persistentContainer = NSPersistentCloudKitContainer(name: modelName)

        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        }

        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }

        do {
            try viewContext.save()
        } catch {
            let error = error as NSError
            fatalError("Unresolved CoreData save error \(error), \(error.userInfo)")
        }
    }
}
