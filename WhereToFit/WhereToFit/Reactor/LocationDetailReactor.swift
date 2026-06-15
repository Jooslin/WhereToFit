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
        case updateAddress(String)
        case updateButtonType(Location.LocationButtonType)
    }
    
    enum Mutation {
        case save
        case setAddress(String)
        case setButtonType(Location.LocationButtonType)
    }
    
    struct State {
        var address: String
        var buttonType: Location.LocationButtonType?
        var name: String
        var selectedLocation: Location?
        
        var registerButtonTitle: String {
            selectedLocation == nil ? "등록하기" : "수정하기"
        }
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
        case .updateAddress(let address):
            return .just(.setAddress(address))
        case .updateButtonType(let buttonType):
            return .just(.setButtonType(buttonType))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .save:
            break
        case .setAddress(let address):
            newState.address = address
        case .setButtonType(let buttonType):
            newState.buttonType = buttonType
        }
        
        return newState
    }
}
