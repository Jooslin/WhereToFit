//
//  RegisteredProgramRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol RegisteredProgramRepositoryProtocol {
    func fetchRegisteredPrograms() -> Single<[RegisteredProgram]>
    func saveRegisteredProgram(_ program: RegisteredProgram) -> Single<RegisteredProgram>
    func deleteRegisteredProgram(id: UUID) -> Completable
}
