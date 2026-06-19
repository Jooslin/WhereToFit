//
//  RemoveFavoriteUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

final class RemoveFavoriteUseCase {
    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(targetType: FavoriteTargetType, targetID: String) -> Completable {
        repository.deleteFavorite(targetType: targetType, targetID: targetID)
    }
}
