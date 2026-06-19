//
//  CoreDataRepositorySupport.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import CoreData
import Foundation

enum CoreDataRepositoryError: Error {
    case missingEntity(String)
}

// entity 이름만 넘기면 NSManagedObject를 만들 수 있도록 확장
// fetch 간단하도록 확장
extension NSManagedObjectContext {
    func insertObject(entityName: String) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: self) else {
            throw CoreDataRepositoryError.missingEntity(entityName)
        }

        return NSManagedObject(entity: entity, insertInto: self)
    }

    func fetchObjects(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0
    ) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit

        return try fetch(request)
    }
}

// 타입 캐스팅 줄일 수 있도록 확장
extension NSManagedObject {
    nonisolated func stringValue(for key: String) -> String? {
        value(forKey: key) as? String
    }

    nonisolated func uuidValue(for key: String) -> UUID? {
        value(forKey: key) as? UUID
    }

    nonisolated func dateValue(for key: String) -> Date? {
        value(forKey: key) as? Date
    }

    nonisolated func doubleValue(for key: String) -> Double? {
        if let value = value(forKey: key) as? Double {
            return value
        }

        return (value(forKey: key) as? NSNumber)?.doubleValue
    }

    nonisolated func intValue(for key: String) -> Int? {
        if let value = value(forKey: key) as? Int {
            return value
        }

        return (value(forKey: key) as? NSNumber)?.intValue
    }

    nonisolated func boolValue(for key: String) -> Bool? {
        if let value = value(forKey: key) as? Bool {
            return value
        }

        return (value(forKey: key) as? NSNumber)?.boolValue
    }
}

enum CoreDataStringArrayCoder {
    nonisolated static func encode(_ values: [String]) -> String? {
        guard values.isEmpty == false else { return nil }
        guard let data = try? JSONEncoder().encode(values) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    nonisolated static func decode(_ value: String?) -> [String] {
        guard let value,
              let data = value.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return decoded
    }
}

enum CoreDataDateArrayCoder {
    nonisolated static func encode(_ values: [Date]) -> String? {
        guard values.isEmpty == false else { return nil }
        guard let data = try? JSONEncoder().encode(values) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    nonisolated static func decode(_ value: String?) -> [Date] {
        guard let value,
              let data = value.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }

        return decoded
    }
}

enum CoreDataDateRange {
    nonisolated static func dayPredicate(key: String, date: Date, calendar: Calendar = .current) -> NSPredicate {
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return NSPredicate(format: "%K >= %@ AND %K < %@", key, startOfDay as NSDate, key, nextDay as NSDate)
    }
}
