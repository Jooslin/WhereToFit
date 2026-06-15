//
//  LocationReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import ReactorKit
import Foundation

final class LocationReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLocations([Location])
    }
    
    struct State {
        var isLoading: Bool = false
        var locations: [Location] = []
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return Observable.concat([
                .just(.setLoading(true)),
                
                .just(.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setLocations(let locations):
            newState.locations = locations
        }
        
        return newState
    }
}
