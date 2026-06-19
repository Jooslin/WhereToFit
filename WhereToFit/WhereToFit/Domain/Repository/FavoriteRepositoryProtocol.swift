//
//  FavoriteRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol FavoriteRepositoryProtocol {
    func fetchFavorites() -> Single<[Favorite]>
    func fetchFavorites(targetType: FavoriteTargetType) -> Single<[Favorite]>
    func saveFavorite(_ favorite: Favorite) -> Single<Favorite>
    func deleteFavorite(targetType: FavoriteTargetType, targetID: String) -> Completable
}
