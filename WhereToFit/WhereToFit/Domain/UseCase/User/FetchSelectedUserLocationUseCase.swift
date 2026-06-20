//
//  FetchSelectedUserLocationUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class FetchSelectedUserLocationUseCase {
    private let repository: UserLocationRepositoryProtocol

    init(repository: UserLocationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userProfileID: UUID) -> Single<UserLocation?> {
        repository.fetchSelectedUserLocation(userProfileID: userProfileID)
    }
}
