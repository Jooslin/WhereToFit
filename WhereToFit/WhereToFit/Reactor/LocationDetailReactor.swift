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
        case updateName(String)
        case updateButtonType(Location.LocationButtonType)
    }
    
    enum Mutation {
        case didUpdateSuccess(Bool)
        case setAddress(String)
        case setName(String)
        case setButtonType(Location.LocationButtonType)
    }
    
    struct State {
        var address: String?
        var buttonType: Location.LocationButtonType?
        var name: String?
        var selectedLocation: Location?
        
        var registerButtonTitle: String {
            selectedLocation == nil ? "등록하기" : "수정하기"
        }
        var isRegisterButtonEnabled: Bool {
            guard let address else { return false }
            return !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        var didUpdateSucess: Bool?
    }
    
    init(location: Location?) {
        if let location {
            self.initialState = State(
                address: location.address,
                buttonType: location.buttonType,
                name: location.name,
                selectedLocation: location
            )
        } else {
            self.initialState = State()
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .update:
            return updateLocation()
        case .updateAddress(let address):
            return .just(.setAddress(address))
        case .updateName(let name):
            return .just(.setName(name))
        case .updateButtonType(let buttonType):
            return .just(.setButtonType(buttonType))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .didUpdateSuccess(let didSuccess):
            newState.didUpdateSucess = didSuccess
        case .setAddress(let address):
            newState.address = address
        case .setName(let name):
            newState.name = name
        case .setButtonType(let buttonType):
            newState.buttonType = buttonType
        }
        
        return newState
    }
}

extension LocationDetailReactor {
    //TODO: location 저장 로직 구현 필요
    private func updateLocation() -> Observable<Mutation> {
        
        //TODO: latitude, longitude 찾아야함
        let location = Location(
            buttonType: currentState.buttonType ?? .additional,
            name: currentState.name ?? currentState.address ?? "",
            address: currentState.address ?? "",
            isSelected: currentState.selectedLocation?.isSelected ?? false,
            latitude: 37,
            longitude: 127
        )
        
        return .just(.didUpdateSuccess(true))
    }
}
