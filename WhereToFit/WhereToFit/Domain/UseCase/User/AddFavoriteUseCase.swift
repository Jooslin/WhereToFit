//
//  AddFavoriteUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

final class AddFavoriteUseCase {
    struct Input {
        let targetType: FavoriteTargetType
        let targetID: String
        let title: String
        let subtitle: String?
        let sportsCategoryRawValue: String?
        let snapshotJSON: String?
    }

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ input: Input) -> Single<Favorite> {
        let now = Date()
        let favorite = Favorite(
            id: UUID(),
            targetType: input.targetType,
            targetID: input.targetID,
            title: input.title,
            subtitle: input.subtitle,
            sportsCategoryRawValue: input.sportsCategoryRawValue,
            snapshotJSON: input.snapshotJSON,
            createdAt: now,
            updatedAt: now
        )

        return repository.saveFavorite(favorite)
    }
}
