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
    let initialState = State(items: [], isEditing: false)
    private let fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase
    private let removeRegisteredProgramUseCase: RemoveRegisteredProgramUseCase

    init(
        fetchRegisteredProgramsUseCase: FetchRegisteredProgramsUseCase,
        removeRegisteredProgramUseCase: RemoveRegisteredProgramUseCase
    ) {
        self.fetchRegisteredProgramsUseCase = fetchRegisteredProgramsUseCase
        self.removeRegisteredProgramUseCase = removeRegisteredProgramUseCase
    }

    enum Action {
        case viewWillAppear
        case toggleEditing
        case removeProgram(RegisteredProgramItem)
    }

    enum Mutation {
        case setItems([RegisteredProgramItem])
        case setEditing(Bool)
    }

    struct State {
        var items: [RegisteredProgramItem]
        var isEditing: Bool
    }

    nonisolated struct RegisteredProgramItem: Equatable {
        let id: UUID
        let programName: String
        let facilityNameText: String?
        let dayText: String
        let timeText: String
        let sportsCategory: SportsCategory?
        let sportsCategoryText: String?
        let reservationMethodText: String?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return fetchRegisteredProgramsUseCase.execute()
                .map { programs in
                    programs.map(Self.makeRegisteredProgramItem)
                }
                .map(Mutation.setItems)
                .asObservable()
                .catch { _ in .just(.setItems([])) }

        case .toggleEditing:
            return .just(.setEditing(currentState.isEditing == false))

        case .removeProgram(let item):
            return removeRegisteredProgramUseCase.execute(id: item.id)
                .andThen(fetchItems())
                .catch { _ in .empty() }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setItems(let items):
            newState.items = items

        case .setEditing(let isEditing):
            newState.isEditing = isEditing
        }

        return newState
    }
}

private extension RegisteredProgramsReactor {
    nonisolated static func makeRegisteredProgramItem(_ program: RegisteredProgram) -> RegisteredProgramItem {
        RegisteredProgramItem(
            id: program.id,
            programName: program.programName,
            facilityNameText: program.facilityName,
            dayText: program.days.isEmpty ? "요일" : program.days.joined(separator: ", "),
            timeText: makeTimeText(startMinute: program.startMinuteOfDay, endMinute: program.endMinuteOfDay),
            sportsCategory: program.sportsCategory,
            sportsCategoryText: program.sportsCategory?.rawValue,
            reservationMethodText: program.reservationMethodRawValues.isEmpty
                ? nil
                : program.reservationMethodRawValues.joined(separator: ", ")
        )
    }

    func fetchItems() -> Observable<Mutation> {
        fetchRegisteredProgramsUseCase.execute()
            .map { programs in
                programs.map(Self.makeRegisteredProgramItem)
            }
            .map(Mutation.setItems)
            .asObservable()
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

}
