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
        case selectFacility(id: UUID)
        case selectDates([Date])
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setDates([Date])
    }
    
    struct State {
        var isLoading: Bool = false
        var dates: [Date] = []
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectFacility(id: let id):
                .empty()
        case .selectDates(let dates):
                .just(.setDates(dates))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setDates(let dates):
            newState.dates = dates
        }
        
        return newState
    }
}
