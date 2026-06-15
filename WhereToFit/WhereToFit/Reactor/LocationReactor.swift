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
        case locationSelected(String)
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
                makeLocationItems(),
                .just(.setLoading(false))
            ])
            
        case .loadItems:
            return .just(.setLocations(currentState.locations))
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

extension LocationReactor {
    //MARK: 데이터 가져오기 수정 필요
    private func makeLocationItems() -> Observable<Mutation> {
        Observable.create { observer in
            let locations: [Location] = [
                Location(
                    icon: .homeFilled,
                    name: "우리동네체육관",
                    address: "경상북도 구미시 송정대로 55",
                    isSelected: true,
                    latitude: 36.1195,
                    longitude: 128.3446
                ),
                Location(
                    icon: .locationPin,
                    name: "구미시민운동장",
                    address: "경상북도 구미시 박정희로 375",
                    isSelected: false,
                    latitude: 36.1107,
                    longitude: 128.3828
                ),
                Location(
                    icon: .locationPin,
                    name: "금오산도립공원",
                    address: "경상북도 구미시 금오산로 400",
                    isSelected: false,
                    latitude: 36.1132,
                    longitude: 128.3087
                )
            ]
            
            observer.onNext(.setLocations(locations))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
