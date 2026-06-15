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
        case update
    }
    
    enum Mutation {
        case save
    }
    
    struct State {
        var isInitial: Bool = true
        var address: String
        var buttonType: Location.LocationButtonType?
        var name: String
        var selectedLocation: Location?
    }
    
    init(address: String?, location: Location?) {
        if let address {
            self.initialState = State(
                address: address,
                name: address
            )
        } else if let location {
            self.initialState = State(
                address: location.address,
                buttonType: location.buttonType,
                name: location.name,
                selectedLocation: location
            )
        } else {
            self.initialState = State(address: "", name: "")
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .update:
            return .just(.save)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .save:
            break
        }
        
        return newState
    }
}
