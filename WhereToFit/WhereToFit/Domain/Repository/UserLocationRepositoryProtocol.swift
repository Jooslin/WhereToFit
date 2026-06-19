//
//  UserLocationRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol UserLocationRepositoryProtocol {
    func fetchUserLocations(userProfileID: UUID) -> Single<[UserLocation]>
    func fetchSelectedUserLocation(userProfileID: UUID) -> Single<UserLocation?>
    func saveUserLocation(_ location: UserLocation) -> Single<UserLocation>
    func deleteUserLocation(id: UUID) -> Completable
}
