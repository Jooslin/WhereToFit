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
    
    enum Action {
        case selectFacility(id: String?, name: String)
        case selectSportsCategory(displayName: String, category: SportsCategory)
        case selectDates([Date])
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setFacility(id: String?, name: String)
        case setSportsCategory(displayName: String, category: SportsCategory)
        case setDates([Date])
    }
    
    struct State {
        var isLoading: Bool = false
        var facilityID: String?
        var facilityName: String?
        var sportsCategoryDisplayName: String?
        var sportsCategory: SportsCategory?
        var dates: [Date] = []
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectFacility(id, name):
                .just(.setFacility(id: id, name: name))
        case let .selectSportsCategory(displayName, category):
                .just(.setSportsCategory(displayName: displayName, category: category))
        case .selectDates(let dates):
                .just(.setDates(dates))
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
        case .setDates(let dates):
            newState.dates = dates
        }
        
        return newState
    }
}
