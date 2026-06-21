//
//  RegisteredProgramReminderProviding.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import Foundation

protocol RegisteredProgramReminderProviding {
    var reminderTarget: ProgramReminderTarget? { get }
}

protocol RegisteredProgramReminderRepositoryProtocol {
    func fetchReminderTargets() throws -> [ProgramReminderTarget]
}
