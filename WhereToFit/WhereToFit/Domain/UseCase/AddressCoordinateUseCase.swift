//
//  AddressCoordinateUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/20/26.
//

import Foundation
import RxSwift

final class AddressCoordinateUseCase {
    private let repository: AddressCoordinateRepositoryProtocol

    init(repository: AddressCoordinateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(address: String) -> Single<GeoCoordinate?> {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAddress.isEmpty == false else {
            return .just(nil)
        }

        return repository.coordinate(for: trimmedAddress)
    }
}
