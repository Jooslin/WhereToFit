//
//  FetchFavoritesUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

final class FetchFavoritesUseCase {
    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(targetType: FavoriteTargetType? = nil) -> Single<[Favorite]> {
        if let targetType {
            return repository.fetchFavorites(targetType: targetType)
        }

        return repository.fetchFavorites()
    }
}
