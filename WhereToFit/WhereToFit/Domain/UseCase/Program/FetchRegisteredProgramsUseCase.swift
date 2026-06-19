//
//  FetchRegisteredProgramsUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

final class FetchRegisteredProgramsUseCase {
    private let repository: RegisteredProgramRepositoryProtocol

    init(repository: RegisteredProgramRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> Single<[RegisteredProgram]> {
        repository.fetchRegisteredPrograms()
    }
}
