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
    
    private let userStore: UserStoreProtocol
    private let addressCoordinateUseCase: AddressCoordinateUseCase
    private let addUserLocationUseCase: AddUserLocationUseCase
    private let updateUserLocationUseCase: UpdateUserLocationUseCase
    
    enum Action {
        case update
        case updateAddress(String)
        case updateName(String)
        case updateButtonType(Location.LocationButtonType)
        case currentLocation
    }
    
    enum Mutation {
        case setAddress(String)
        case setName(String)
        case setButtonType(Location.LocationButtonType)
        
        case setLoading(Bool)
        case setUpdateResult(Bool)
    }
    
    struct State {
        var address: String?
        var buttonType: Location.LocationButtonType?
        var name: String?
        var selectedLocation: UserLocation?
        
        var registerButtonTitle: String {
            selectedLocation == nil ? "등록하기" : "수정하기"
        }
        var isRegisterButtonEnabled: Bool {
            guard let address else { return false }
            return !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var isLoading: Bool = false
        @Pulse var updateResult: Bool?
    }
    
    init(
        userStore: UserStoreProtocol,
        location: UserLocation?,
        addressCoordinateUseCase: AddressCoordinateUseCase = AddressCoordinateUseCase(
            repository: NaverMapSearchRepository()
        ),
        addUserLocationUseCase: AddUserLocationUseCase = AddUserLocationUseCase(
            repository: CoreDataUserLocationRepository()
        ),
        updateUserLocationUseCase: UpdateUserLocationUseCase = UpdateUserLocationUseCase(
            repository: CoreDataUserLocationRepository()
        )
    ) {
        self.userStore = userStore
        self.addressCoordinateUseCase = addressCoordinateUseCase
        self.addUserLocationUseCase = addUserLocationUseCase
        self.updateUserLocationUseCase = updateUserLocationUseCase
        
        if let location {
            self.initialState = State(
                address: location.address,
                buttonType: location.kind.buttonType,
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
            guard !currentState.isLoading else { return .empty() }
            
            return Observable.concat([
                .just(.setLoading(true)),
                updateLocation(),
                .just(.setLoading(false))
                ])
            
        case .updateAddress(let address):
            return .just(.setAddress(address))
            
        case .currentLocation:
            return currentLocation()
            
        case .updateName(let name):
            return .just(.setName(name))
            
        case .updateButtonType(let buttonType):
            return .just(.setButtonType(buttonType))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setAddress(let address):
            newState.address = address
        case .setName(let name):
            newState.name = name
        case .setButtonType(let buttonType):
            newState.buttonType = buttonType
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setUpdateResult(let isSuccess):
            newState.updateResult = isSuccess
        }
        
        return newState
    }
}

extension LocationDetailReactor {
    private func updateLocation() -> Observable<Mutation> {
        let address = currentState.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard address.isEmpty == false else {
            return .just(.setUpdateResult(false))
        }
        
        return userStore.userProfile
            .take(1)
            .flatMap { [weak self] profile -> Observable<Mutation> in
                guard let self,
                      let profile else {
                    return .just(.setUpdateResult(false))
                }
                
                return self.saveLocation(address: address, userProfileID: profile.id)
            }
    }
    
    private func currentLocation() -> Observable<Mutation> {
        //TODO: 현재 위치 뱉는 로직
        
        return .just(.setAddress("현재 주소"))
    }
}

private extension LocationDetailReactor {
    func saveLocation(address: String, userProfileID: UUID) -> Observable<Mutation> {
        addressCoordinateUseCase.execute(address: address)
            .flatMap { [weak self] coordinate -> Single<UserLocation> in
                guard let self,
                      let coordinate else {
                    return .error(LocationDetailError.coordinateNotFound)
                }
                
                let buttonType = currentState.buttonType ?? currentState.selectedLocation?.kind.buttonType ?? .additional
                let name = currentState.name ?? currentState.selectedLocation?.name
                
                if let selectedLocation = currentState.selectedLocation {
                    let input = UpdateUserLocationUseCase.Input(
                        id: selectedLocation.id,
                        userProfileID: userProfileID,
                        name: name,
                        address: address,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        isSelected: selectedLocation.isSelected,
                        kind: buttonType.userLocationKind,
                        createdAt: selectedLocation.createdAt
                    )
                    
                    return updateUserLocationUseCase.execute(input)
                }
                
                let input = AddUserLocationUseCase.Input(
                    userProfileID: userProfileID,
                    name: name,
                    address: address,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    isSelected: false,
                    kind: buttonType.userLocationKind
                )
                
                return addUserLocationUseCase.execute(input)
            }
            .asObservable()
            .do(onNext: { [userStore] location in
                guard location.isSelected else { return }
                userStore.setCurrnetLocation(location)
            })
            .map { _ in Mutation.setUpdateResult(true) }
            .catch { _ in .just(.setUpdateResult(false)) }
    }
}

private enum LocationDetailError: Error {
    case coordinateNotFound
}

private extension UserLocationKind {
    var buttonType: Location.LocationButtonType {
        switch self {
        case .home:
            return .myHome
        case .office:
            return .office
        case .custom:
            return .additional
        }
    }
}

private extension Location.LocationButtonType {
    var userLocationKind: UserLocationKind {
        switch self {
        case .myHome:
            return .home
        case .office:
            return .office
        case .additional:
            return .custom
        }
    }
}
