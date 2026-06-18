//
//  FavoriteRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol FavoriteRepositoryProtocol {
    func fetchFavorites(userProfileID: UUID) -> Single<[Favorite]>
    func fetchFavorites(userProfileID: UUID, targetType: FavoriteTargetType) -> Single<[Favorite]>
    func saveFavorite(_ favorite: Favorite) -> Single<Favorite>
    func deleteFavorite(userProfileID: UUID, targetType: FavoriteTargetType, targetID: String) -> Completable
}
