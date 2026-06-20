//
//  RemoveRegisteredProgramUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/20/26.
//

import Foundation
import RxSwift

final class RemoveRegisteredProgramUseCase {
    private let repository: RegisteredProgramRepositoryProtocol

    init(repository: RegisteredProgramRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) -> Completable {
        repository.deleteRegisteredProgram(id: id)
    }
}
