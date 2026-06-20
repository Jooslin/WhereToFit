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
    let initialState = State(items: [])
    private let fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase

    init(fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase) {
        self.fetchRegisteredProgramsUseCase = fetchRegisteredProgramsUseCase
    }

    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setItems([RegisteredProgramItem])
    }

    struct State {
        var items: [RegisteredProgramItem]
    }

    nonisolated struct RegisteredProgramItem: Equatable {
        let programName: String
        let facilityNameText: String?
        let dayText: String
        let timeText: String
        let sportsCategoryText: String?
        let reservationMethodText: String?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return fetchRegisteredProgramsUseCase.execute()
                .do(onSuccess: { programs in
                    Self.printRegisteredPrograms(programs)
                })
                .map { programs in
                    programs.map(Self.makeRegisteredProgramItem)
                }
                .map(Mutation.setItems)
                .asObservable()
                .catch { error in
                    print("[RegisteredPrograms][Fetch][Error] \(error.localizedDescription)")
                    return .just(.setItems([]))
                }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setItems(let items):
            newState.items = items
        }

        return newState
    }
}

private extension RegisteredProgramsReactor {
    nonisolated static func makeRegisteredProgramItem(_ program: RegisteredProgram) -> RegisteredProgramItem {
        RegisteredProgramItem(
            programName: program.programName,
            facilityNameText: program.facilityName,
            dayText: program.days.isEmpty ? "요일" : program.days.joined(separator: ", "),
            timeText: makeTimeText(startMinute: program.startMinuteOfDay, endMinute: program.endMinuteOfDay),
            sportsCategoryText: program.sportsCategory?.rawValue,
            reservationMethodText: program.reservationMethodRawValues.isEmpty
                ? nil
                : program.reservationMethodRawValues.joined(separator: ", ")
        )
    }

    nonisolated static func makeTimeText(startMinute: Int?, endMinute: Int?) -> String {
        guard let startMinute, let endMinute else {
            return "시간 미정"
        }

        return "\(makeClockText(minuteOfDay: startMinute))-\(makeClockText(minuteOfDay: endMinute))"
    }

    nonisolated static func makeClockText(minuteOfDay: Int) -> String {
        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    nonisolated static func printRegisteredPrograms(_ programs: [RegisteredProgram]) {
        print("[RegisteredPrograms][Fetch] count: \(programs.count)")

        programs.enumerated().forEach { index, program in
            print(
                """
                👁️🫦👁️[RegisteredPrograms][\(index)]
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
