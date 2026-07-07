//
//  NotificationHistoryStore.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation
import UserNotifications

struct NotificationHistoryItem: Codable, Hashable {
    let id: String
    let typeTitle: String
    let message: String
    let receivedAt: Date
    let notificationIdentifier: String

    var isProgramNotification: Bool {
        NotificationNavigationStepper.shared.isProgramNotification(identifier: notificationIdentifier)
    }
}

final class NotificationHistoryStore {
    static let shared = NotificationHistoryStore()

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.wheretofit.notification-history-store")
    private let key = "notificationHistoryItems"
    private let maxItemCount = 100

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> [NotificationHistoryItem] {
        queue.sync {
            loadUnlocked()
        }
    }

    func save(notification: UNNotification) {
        merge([NotificationHistoryItem(notification: notification)])
    }

    func merge(notifications: [UNNotification]) {
        merge(notifications.map(NotificationHistoryItem.init(notification:)))
    }

    func merge(_ items: [NotificationHistoryItem]) {
        queue.sync {
            var itemsByID = Dictionary(
                uniqueKeysWithValues: loadUnlocked().map { ($0.id, $0) }
            )

            items.forEach { item in
                itemsByID[item.id] = item
            }

            let sortedItems = itemsByID.values
                .sorted { $0.receivedAt > $1.receivedAt }
                .prefix(maxItemCount)

            saveUnlocked(Array(sortedItems))
        }
    }
}

private extension NotificationHistoryStore {
    func loadUnlocked() -> [NotificationHistoryItem] {
        guard let data = userDefaults.data(forKey: key),
              let items = try? decoder.decode([NotificationHistoryItem].self, from: data) else {
            return []
        }

        return items.sorted { $0.receivedAt > $1.receivedAt }
    }

    func saveUnlocked(_ items: [NotificationHistoryItem]) {
        guard let data = try? encoder.encode(items) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}

private extension NotificationHistoryItem {
    init(notification: UNNotification) {
        let content = notification.request.content
        let message = content.body.trimmedForNotificationHistory()
            ?? content.title.trimmedForNotificationHistory()
            ?? "알림이 도착했어요."

        self.init(
            id: notification.request.identifier,
            typeTitle: Self.typeTitle(for: notification),
            message: message,
            receivedAt: notification.date,
            notificationIdentifier: notification.request.identifier
        )
    }

    static func typeTitle(for notification: UNNotification) -> String {
        if NotificationNavigationStepper.shared.isProgramNotification(identifier: notification.request.identifier) {
            return "프로그램"
        }

        return notification.request.content.title.trimmedForNotificationHistory() ?? "알림"
    }
}

private extension String {
    func trimmedForNotificationHistory() -> String? {
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}
