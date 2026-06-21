//
//  FetchUserProfileUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class FetchUserProfileUseCase {
    private let repository: UserProfileRepositoryProtocol

    init(repository: UserProfileRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> Single<UserProfile?> {
        repository.fetchUserProfile()
    }
}
