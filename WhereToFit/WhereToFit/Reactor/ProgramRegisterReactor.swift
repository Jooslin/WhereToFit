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

    init(fetchFacilityProgramsUseCase: FetchFacilityProgramsUseCase) {
        self.fetchFacilityProgramsUseCase = fetchFacilityProgramsUseCase
    }
    
    enum Action {
        case selectFacility(id: String?, name: String)
        case selectSportsCategory(displayName: String, category: SportsCategory)
        case selectProgram(ProgramOption)
        case selectDirectProgramInput
        case updateProgramName(String)
        case finishProgramDirectInput
        case selectDates([Date])
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setFacility(id: String?, name: String)
        case setSportsCategory(displayName: String, category: SportsCategory)
        case setProgramOptions([ProgramOption])
        case setProgram(id: Int?, name: String?)
        case setProgramDirectInputEnabled(Bool)
        case setDates([Date])
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
        var dates: [Date] = []
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
        case .selectDates(let dates):
            return .just(.setDates(dates))
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
        case .setDates(let dates):
            newState.dates = dates
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
}
