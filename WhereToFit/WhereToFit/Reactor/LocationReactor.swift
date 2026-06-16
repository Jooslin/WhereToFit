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
        case selected(Location)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLocations([Location])
        case setDataSource([LocationView.Item])
    }
    
    struct State {
        var isLoading: Bool = false
        var data: [LocationView.Section: [LocationView.Item]] = [.button:[LocationView.Item.button]]
        var locations: [Location] = []
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
            guard !currentState.isLoading else { return .empty() }
            
            return Observable.concat([
                .just(.setLoading(true)),
                updateSelectedLocation(location),
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
        }
        
        return newState
    }
}

extension LocationReactor {
    //TODO: 데이터 가져오기 수정 필요
    private func makeLocationItems() -> Observable<Mutation> {
        Observable.create { observer in
            let locations: [Location] = [
                Location(
                    buttonType: .myHome,
                    name: "우리동네체육관",
                    address: "경상북도 구미시 송정대로 55",
                    isSelected: true,
                    latitude: 36.1195,
                    longitude: 128.3446
                ),
                Location(
                    buttonType: .additional,
                    name: "구미시민운동장",
                    address: "경상북도 구미시 박정희로 375",
                    isSelected: false,
                    latitude: 36.1107,
                    longitude: 128.3828
                ),
                Location(
                    buttonType: .additional,
                    name: "금오산도립공원",
                    address: "경상북도 구미시 금오산로 400",
                    isSelected: false,
                    latitude: 36.1132,
                    longitude: 128.3087
                )
            ]
            
            let items = locations.reduce([LocationView.Item]()) {
                $0 + [LocationView.Item.location($1)]
            }
            
            observer.onNext(.setLocations(locations))
            observer.onNext(.setDataSource(items))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    //TODO: selectedLocation 업데이트 로직 필요
    private func updateSelectedLocation(_ location: Location) -> Observable<Mutation> {
        // 현재 isSelected = true인 location 찾기
        // 현재 isSelected location 값을 false로, 파라미터로 받은 location.isSelected = true로 수정
        // 새로 모든 아이템 받아와서 .setLocations 반환
            Observable.create { observer in
                let locations: [Location] = [
                    Location(
                        buttonType: .myHome,
                        name: "우리동네체육관",
                        address: "경상북도 구미시 송정대로 55",
                        isSelected: true,
                        latitude: 36.1195,
                        longitude: 128.3446
                    ),
                    Location(
                        buttonType: .additional,
                        name: "구미시민운동장",
                        address: "경상북도 구미시 박정희로 375",
                        isSelected: false,
                        latitude: 36.1107,
                        longitude: 128.3828
                    ),
                    Location(
                        buttonType: .additional,
                        name: "금오산도립공원",
                        address: "경상북도 구미시 금오산로 400",
                        isSelected: false,
                        latitude: 36.1132,
                        longitude: 128.3087
                    )
                ]
                
                let items = locations.reduce([LocationView.Item]()) {
                    $0 + [LocationView.Item.location($1)]
                }
                
                observer.onNext(.setLocations(locations))
                observer.onNext(.setDataSource(items))
                observer.onCompleted()
                
                return Disposables.create()
            }
    }
}
