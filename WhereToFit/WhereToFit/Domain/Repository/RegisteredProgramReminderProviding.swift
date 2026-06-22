//
//  RegisteredProgramReminderProviding.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import Foundation
import RxSwift

protocol RegisteredProgramReminderProviding {
    var reminderTarget: ProgramReminderTarget? { get }
}

protocol RegisteredProgramReminderRepositoryProtocol {
    func fetchReminderTargets() -> Single<[ProgramReminderTarget]>
}
