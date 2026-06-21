//
//  ProgramRegisterReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import ReactorKit
import Foundation

final class ProgramRegisterReactor: BaseReactor {
    let initialState: State = State()
    private let fetchFacilityProgramsUseCase: FetchFacilityProgramsUseCase
    private let saveRegisteredProgramUseCase: SaveRegisteredProgramUseCase

    init(
        fetchFacilityProgramsUseCase: FetchFacilityProgramsUseCase,
        saveRegisteredProgramUseCase: SaveRegisteredProgramUseCase
    ) {
        self.fetchFacilityProgramsUseCase = fetchFacilityProgramsUseCase
        self.saveRegisteredProgramUseCase = saveRegisteredProgramUseCase
    }
    
    enum Action {
        case selectFacility(id: String?, name: String)
        case selectSportsCategory(displayName: String, category: SportsCategory)
        case selectProgram(ProgramOption)
        case selectDirectProgramInput
        case updateProgramName(String)
        case finishProgramDirectInput
        case toggleRecurring
        case toggleReservationDates
        case toggleWeekday(Weekday)
        case selectDates([Date])
        case selectStartTime(Int?)
        case selectEndTime(Int?)
        case save
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setFacility(id: String?, name: String)
        case setSportsCategory(displayName: String, category: SportsCategory)
        case setProgramOptions([ProgramOption])
        case setProgram(id: Int?, name: String?)
        case setProgramDirectInputEnabled(Bool)
        case setRecurring(Bool)
        case setReservationDatesEnabled(Bool)
        case setWeekdays(Set<Weekday>)
        case setDates([Date])
        case setStartTime(Int?)
        case setEndTime(Int?)
        case setSaveResult(Bool)
    }
    
    nonisolated struct ProgramOption: Equatable {
        let id: Int?
        let name: String
    }

    struct State {
        var isLoading: Bool = false
        var facilityID: String?
        var facilityName: String?
        var sportsCategoryDisplayName: String?
        var sportsCategory: SportsCategory?
        var programOptions: [ProgramOption] = []
        var programID: Int?
        var programName: String?
        var isProgramDirectInputEnabled: Bool = false
        var isRecurring: Bool = false
        var selectedWeekdays: Set<Weekday> = []
        var hasReservationDates: Bool = false
        var dates: [Date] = []
        var startMinuteOfDay: Int?
        var endMinuteOfDay: Int?
        @Pulse var saveResult: Bool?

        var isRegisterButtonEnabled: Bool {
            guard isLoading == false else {
                return false
            }

            guard let programName,
                  programName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                  let facilityName,
                  facilityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                  sportsCategory != nil else {
                return false
            }

            return true
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectFacility(id, name):
            return .concat([
                .just(.setFacility(id: id, name: name)),
                .just(.setProgram(id: nil, name: nil)),
                .just(.setProgramDirectInputEnabled(false)),
                .just(.setProgramOptions([])),
                fetchProgramOptions(facilityID: id, sportName: currentState.sportsCategoryDisplayName)
            ])
        case let .selectSportsCategory(displayName, category):
            return .concat([
                .just(.setSportsCategory(displayName: displayName, category: category)),
                .just(.setProgram(id: nil, name: nil)),
                .just(.setProgramDirectInputEnabled(false)),
                .just(.setProgramOptions([])),
                fetchProgramOptions(facilityID: currentState.facilityID, sportName: displayName)
            ])
        case let .selectProgram(option):
            return .concat([
                .just(.setProgram(id: option.id, name: option.name)),
                .just(.setProgramDirectInputEnabled(false))
            ])
        case .selectDirectProgramInput:
            return .concat([
                .just(.setProgram(id: nil, name: nil)),
                .just(.setProgramDirectInputEnabled(true))
            ])
        case let .updateProgramName(name):
            return .just(.setProgram(id: nil, name: name))
        case .finishProgramDirectInput:
            return .just(.setProgramDirectInputEnabled(false))
        case .toggleRecurring:
            return .just(.setRecurring(currentState.isRecurring == false))
        case .toggleReservationDates:
            return .just(.setReservationDatesEnabled(currentState.hasReservationDates == false))
        case let .toggleWeekday(weekday):
            var weekdays = currentState.selectedWeekdays
            if weekdays.contains(weekday) {
                weekdays.remove(weekday)
            } else {
                weekdays.insert(weekday)
            }
            return .just(.setWeekdays(weekdays))
        case .selectDates(let dates):
            return .just(.setDates(dates))
        case .selectStartTime(let minuteOfDay):
            var mutations: [Observable<Mutation>] = [.just(.setStartTime(minuteOfDay))]
            if let minuteOfDay,
               let endMinuteOfDay = currentState.endMinuteOfDay,
               endMinuteOfDay < minuteOfDay {
                mutations.append(.just(.setEndTime(nil)))
            }

            return .concat(mutations)
        case .selectEndTime(let minuteOfDay):
            if let minuteOfDay,
               let startMinuteOfDay = currentState.startMinuteOfDay,
               minuteOfDay < startMinuteOfDay {
                return .just(.setEndTime(startMinuteOfDay))
            }

            return .just(.setEndTime(minuteOfDay))
        case .save:
            guard currentState.isLoading == false else {
                return .empty()
            }

            guard currentState.isRegisterButtonEnabled else {
                return .just(.setSaveResult(false))
            }

            return .concat([
                .just(.setLoading(true)),
                saveRegisteredProgram(),
                .just(.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case let .setFacility(id, name):
            newState.facilityID = id
            newState.facilityName = name
        case let .setSportsCategory(displayName, category):
            newState.sportsCategoryDisplayName = displayName
            newState.sportsCategory = category
        case .setProgramOptions(let options):
            newState.programOptions = options
        case let .setProgram(id, name):
            newState.programID = id
            newState.programName = name
        case .setProgramDirectInputEnabled(let isEnabled):
            newState.isProgramDirectInputEnabled = isEnabled
        case .setRecurring(let isRecurring):
            newState.isRecurring = isRecurring
        case .setReservationDatesEnabled(let hasReservationDates):
            newState.hasReservationDates = hasReservationDates
        case .setWeekdays(let weekdays):
            newState.selectedWeekdays = weekdays
        case .setDates(let dates):
            newState.dates = dates
        case .setStartTime(let minuteOfDay):
            newState.startMinuteOfDay = minuteOfDay
        case .setEndTime(let minuteOfDay):
            newState.endMinuteOfDay = minuteOfDay
        case .setSaveResult(let isSuccess):
            newState.saveResult = isSuccess
        }
        
        return newState
    }
}

private extension ProgramRegisterReactor {
    func fetchProgramOptions(facilityID: String?, sportName: String?) -> Observable<Mutation> {
        fetchFacilityProgramsUseCase.execute(facilityID: facilityID, sportName: sportName)
            .asObservable()
            .map { programs in
                programs.compactMap { program in
                    guard let name = program.className?.trimmingCharacters(in: .whitespacesAndNewlines),
                          name.isEmpty == false else {
                        return nil
                    }

                    return ProgramOption(id: program.id, name: name)
                }
            }
            .map(Mutation.setProgramOptions)
            .catchAndReturn(.setProgramOptions([]))
    }

    func saveRegisteredProgram() -> Observable<Mutation> {
        let input = SaveRegisteredProgramUseCase.Input(
            programID: currentState.programID,
            facilityID: currentState.facilityID,
            programName: currentState.programName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            facilityName: currentState.facilityName?.trimmingCharacters(in: .whitespacesAndNewlines),
            sportsCategory: currentState.sportsCategory,
            isRecurring: currentState.isRecurring,
            days: currentState.selectedWeekdays
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.title),
            hasReservationDates: currentState.hasReservationDates,
            reservationDates: currentState.dates,
            startMinuteOfDay: currentState.startMinuteOfDay,
            endMinuteOfDay: currentState.endMinuteOfDay,
            reservationMethodRawValues: []
        )

        return saveRegisteredProgramUseCase.execute(input)
            .asObservable()
            .map { _ in Mutation.setSaveResult(true) }
            .catchAndReturn(.setSaveResult(false))
    }
}
