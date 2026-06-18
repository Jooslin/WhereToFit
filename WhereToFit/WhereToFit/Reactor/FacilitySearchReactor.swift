//
//  FacilitySearchReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/18/26.
//

import ReactorKit
import Foundation

final class FacilitySearchReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        
    }
    
    enum Mutation {
        case setLoading(Bool)
    }
    
    struct State {
        var isLoading: Bool = false
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        
        return newState
    }
}
