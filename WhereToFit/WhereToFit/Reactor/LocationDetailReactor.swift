//
//  LocationEditReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import ReactorKit
import Foundation

final class LocationDetailReactor: BaseReactor {
    let initialState: State
    
    enum Action {

    }
    
    enum Mutation {

    }
    
    struct State {
        var isLoading: Bool = false
        var selectedAddress: String?
        var selectedLocation: Location?
    }
    
    init(address: String?, location: Location?) {
        self.initialState = State(
            isLoading: false,
            selectedAddress: address,
            selectedLocation: location
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
  
        }
        
        return newState
    }
}
