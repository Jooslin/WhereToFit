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
        case loadItems
        case selected(UserLocation)
        case updateSelection
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLocations([UserLocation])
        case setDataSource([LocationView.Item])
        case setSelectedLocation(UserLocation?)
        case setUpdateResult(Bool)
    }
    
    struct State {
        var isLoading: Bool = false
        var data: [LocationView.Section: [LocationView.Item]] = [.button:[LocationView.Item.button]]
        var locations: [UserLocation] = []
        var selectedLocation: UserLocation?
        @Pulse var updateResult: Bool?
    }
    
    private let userStore: UserStoreProtocol
    private let fetchUserLocationsUseCase: FetchUserLocationsUseCase
    
    init(
        userStore: UserStoreProtocol,
        fetchUserLocationsUseCase: FetchUserLocationsUseCase = FetchUserLocationsUseCase(
            repository: CoreDataUserLocationRepository()
        )
    ) {
        self.userStore = userStore
        self.fetchUserLocationsUseCase = fetchUserLocationsUseCase
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            guard !currentState.isLoading else { return .empty() }
            
            return Observable.concat([
                .just(.setLoading(true)),
                makeLocationItems(),
                .just(.setLoading(false))
            ])
            
        case .loadItems:
            return .just(.setLocations(currentState.locations))
            
        case .selected(let location):
            return updateSelectedLocation(location)
            
        case .updateSelection:
            guard !currentState.isLoading else { return .empty() }
            
            return Observable.concat([
                .just(.setLoading(true)),
                updateSelectedLocationCoreData(),
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
        case .setDataSource(let items):
            newState.data[.location] = items
        case .setSelectedLocation(let location):
            newState.selectedLocation = location
        case .setUpdateResult(let isSuccess):
            newState.updateResult = isSuccess
        }
        
        return newState
    }
}

extension LocationReactor {
    private func makeLocationItems() -> Observable<Mutation> {
        userStore.userProfile
            .take(1)
            .flatMap { [fetchUserLocationsUseCase] profile -> Observable<[UserLocation]> in
                guard let profile else { return .just([]) }
                
                return fetchUserLocationsUseCase.execute(userProfileID: profile.id)
                    .asObservable()
            }
            .flatMap { locations -> Observable<Mutation> in
                let items = locations.map(LocationView.Item.location)
                
                return Observable.from([
                    .setLocations(locations),
                    .setDataSource(items),
                    .setSelectedLocation(locations.first { $0.isSelected })
                ])
            }
            .catch { _ in
                Observable.from([
                    .setLocations([]),
                    .setDataSource([]),
                    .setSelectedLocation(nil)
                ])
            }
    }
    
    //TODO: selectedLocation 업데이트 로직 필요
    private func updateSelectedLocation(_ location: UserLocation) -> Observable<Mutation> {
        .just(.setSelectedLocation(location))
    }
    
    private func updateSelectedLocationCoreData() -> Observable<Mutation> {
        // State의 selectedLocation의 isSelected를 변경!
        // 기존 isSelected == true 값은 false로 변경
        Observable.create { observer in
            
            observer.onNext(.setUpdateResult(true))
            observer.onCompleted()
            
            return Disposables.create()
        }
        
    }
}
