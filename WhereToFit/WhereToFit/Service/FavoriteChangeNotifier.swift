//
//  FavoriteChangeNotifier.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation

struct FavoriteChange {
    let targetKey: FavoriteTargetKey
    let isFavorite: Bool
}

enum FavoriteChangeNotifier {
    static let notificationName = Notification.Name("FavoriteChangeNotifier.favoriteDidChange")

    private static let targetTypeKey = "targetType"
    private static let targetIDKey = "targetID"
    private static let isFavoriteKey = "isFavorite"

    static func post(
        targetType: FavoriteTargetType,
        targetID: String,
        isFavorite: Bool
    ) {
        NotificationCenter.default.post(
            name: notificationName,
            object: nil,
            userInfo: [
                targetTypeKey: targetType.rawValue,
                targetIDKey: targetID,
                isFavoriteKey: isFavorite
            ]
        )
    }

    static func change(from notification: Notification) -> FavoriteChange? {
        guard let userInfo = notification.userInfo,
              let targetTypeRawValue = userInfo[targetTypeKey] as? String,
              let targetType = FavoriteTargetType(rawValue: targetTypeRawValue),
              let targetID = userInfo[targetIDKey] as? String,
              let isFavorite = userInfo[isFavoriteKey] as? Bool else {
            return nil
        }

        return FavoriteChange(
            targetKey: FavoriteTargetKey(targetType: targetType, targetID: targetID),
            isFavorite: isFavorite
        )
    }
}
