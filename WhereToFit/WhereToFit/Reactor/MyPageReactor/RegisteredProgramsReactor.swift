//
//  RegisteredProgramsReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import Foundation
import ReactorKit
import RxSwift

final class RegisteredProgramsReactor: BaseReactor {
    let initialState = State(programs: [])
    private let fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase

    init(fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase) {
        self.fetchRegisteredProgramsUseCase = fetchRegisteredProgramsUseCase
    }

    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setPrograms([RegisteredProgram])
    }

    struct State {
        var programs: [RegisteredProgram]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return fetchRegisteredProgramsUseCase.execute()
                .do(onSuccess: { programs in
                    Self.printRegisteredPrograms(programs)
                })
                .map(Mutation.setPrograms)
                .asObservable()
                .catch { error in
                    print("[RegisteredPrograms][Fetch][Error] \(error.localizedDescription)")
                    return .just(.setPrograms([]))
                }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setPrograms(let programs):
            newState.programs = programs
        }

        return newState
    }
}

private extension RegisteredProgramsReactor {
    nonisolated static func printRegisteredPrograms(_ programs: [RegisteredProgram]) {
        print("[RegisteredPrograms][Fetch] count: \(programs.count)")

        programs.enumerated().forEach { index, program in
            print(
                """
                [RegisteredPrograms][\(index)]
                id: \(program.id)
                programID: \(program.programID.map(String.init) ?? "nil")
                facilityID: \(program.facilityID ?? "nil")
                programName: \(program.programName)
                facilityName: \(program.facilityName ?? "nil")
                sportsCategory: \(program.sportsCategory?.rawValue ?? "nil")
                isRecurring: \(program.isRecurring)
                days: \(program.days)
                hasReservationDates: \(program.hasReservationDates)
                reservationDates: \(program.reservationDates)
                startMinuteOfDay: \(program.startMinuteOfDay.map(String.init) ?? "nil")
                endMinuteOfDay: \(program.endMinuteOfDay.map(String.init) ?? "nil")
                reservationMethodRawValues: \(program.reservationMethodRawValues)
                createdAt: \(program.createdAt)
                updatedAt: \(program.updatedAt)
                """
            )
        }
    }
}
