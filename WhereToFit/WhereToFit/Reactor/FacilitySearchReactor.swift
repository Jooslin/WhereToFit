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
    private let userStore: UserStoreProtocol
    private let fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase
    
    init(
        userStore: UserStoreProtocol,
        fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase
    ) {
        self.userStore = userStore
        self.fetchNearbyFacilitiesUseCase = fetchNearbyFacilitiesUseCase
    }
    
    enum Action {
        case viewDidLoad
        case searchTextChanged(String)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setReferenceCoordinate(GeoCoordinate)
        case setSearchText(String)
        case setSearchResults(query: String, [FacilitySearchResult])
        case setErrorMessage(query: String, String?)
    }
    
    struct State {
        var isLoading: Bool = false
        var referenceCoordinate: GeoCoordinate = FacilitySearchReactor.defaultCoordinate
        var searchText: String = ""
        var searchResults: [FacilitySearchResult] = []
        var errorMessage: String?
        var shouldShowEmptyState: Bool {
            searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                && searchResults.isEmpty
                && isLoading == false
        }
    }
    
    struct FacilitySearchResult: Hashable {
        let id: String
        let name: String
        let address: String
        let distanceText: String
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return userStore.currentLocation
                .take(1)
                .map(Self.referenceCoordinate)
                .map(Mutation.setReferenceCoordinate)
            
        case .searchTextChanged(let searchText):
            let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedSearchText.isEmpty == false else {
                return .from([
                    .setSearchText(searchText),
                    .setSearchResults(query: searchText, []),
                    .setErrorMessage(query: searchText, nil),
                    .setLoading(false)
                ])
            }
            
            return .concat([
                .just(.setSearchText(searchText)),
                .just(.setLoading(true)),
                .just(.setSearchResults(query: searchText, [])),
                fetchNearbyFacilitiesUseCase.searchFacilities(keyword: trimmedSearchText)
                    .asObservable()
                    .map { facilities in
                        Self.makeSearchResults(
                            query: trimmedSearchText,
                            facilities: facilities,
                            referenceCoordinate: self.currentState.referenceCoordinate
                        )
                    }
                    .flatMap { results -> Observable<Mutation> in
                        .from([
                            .setSearchResults(query: searchText, results),
                            .setErrorMessage(query: searchText, nil)
                        ])
                    }
                    .catch { error in
                        .from([
                            .setSearchResults(query: searchText, []),
                            .setErrorMessage(query: searchText, error.localizedDescription)
                        ])
                    },
                .just(.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setReferenceCoordinate(let coordinate):
            newState.referenceCoordinate = coordinate
        case .setSearchText(let searchText):
            newState.searchText = searchText
        case let .setSearchResults(query, results):
            guard state.matchesCurrentSearchText(query) else { return state }
            newState.searchResults = results
        case let .setErrorMessage(query, message):
            guard state.matchesCurrentSearchText(query) else { return state }
            newState.errorMessage = message
        }
        
        return newState
    }
}

private extension FacilitySearchReactor {
    nonisolated static let defaultCoordinate = GeoCoordinate(latitude: 37.576022, longitude: 126.976900)
    
    nonisolated static func referenceCoordinate(from location: UserLocation?) -> GeoCoordinate {
        guard let location else { return defaultCoordinate }
        return GeoCoordinate(latitude: location.latitude, longitude: location.longitude)
    }
    
    nonisolated static func makeSearchResults(
        query: String,
        facilities: [FitnessFacility],
        referenceCoordinate: GeoCoordinate
    ) -> [FacilitySearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }
        
        var nearestItemsByName: [String: (facility: FitnessFacility, distanceInMeters: Int)] = [:]
        
        facilities
            .filter { $0.matchesFacilitySearchQuery(trimmedQuery) }
            .forEach { facility in
                let key = facility.name.normalizedFacilitySearchText
                let calculatedDistance = distanceInMeters(
                    from: referenceCoordinate,
                    to: facility.coordinate
                )
                
                guard let existingItem = nearestItemsByName[key] else {
                    nearestItemsByName[key] = (facility, calculatedDistance)
                    return
                }
                
                if calculatedDistance < existingItem.distanceInMeters {
                    nearestItemsByName[key] = (facility, calculatedDistance)
                }
            }
        
        return nearestItemsByName.values
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
            .map { item in
                FacilitySearchResult(
                    id: item.facility.id,
                    name: item.facility.name,
                    address: item.facility.address,
                    distanceText: formatDistanceText(item.distanceInMeters)
                )
            }
    }
    
    nonisolated static func distanceInMeters(from source: GeoCoordinate, to destination: GeoCoordinate) -> Int {
        let earthRadiusInMeters = 6_371_000.0
        let sourceLatitude = source.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let latitudeDelta = (destination.latitude - source.latitude) * .pi / 180
        let longitudeDelta = (destination.longitude - source.longitude) * .pi / 180
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(sourceLatitude) * cos(destinationLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        let angularDistance = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        
        return Int((earthRadiusInMeters * angularDistance).rounded())
    }
    
    nonisolated static func formatDistanceText(_ distanceInMeters: Int) -> String {
        guard distanceInMeters >= 1000 else {
            return "\(distanceInMeters)m"
        }
        
        let distanceInKilometers = Double(distanceInMeters) / 1000
        if distanceInKilometers >= 10 {
            return "\(Int(distanceInKilometers.rounded()))km"
        }
        
        let roundedDistance = (distanceInKilometers * 10).rounded() / 10
        if roundedDistance == roundedDistance.rounded() {
            return "\(Int(roundedDistance))km"
        }
        
        return String(format: "%.1fkm", roundedDistance)
    }
}

private extension FitnessFacility {
    nonisolated func matchesFacilitySearchQuery(_ query: String) -> Bool {
        let normalizedQuery = query.normalizedFacilitySearchText
        guard normalizedQuery.isEmpty == false else { return false }
        
        return name.normalizedFacilitySearchText.contains(normalizedQuery)
    }
}

private extension FacilitySearchReactor.State {
    nonisolated func matchesCurrentSearchText(_ query: String) -> Bool {
        searchText.normalizedFacilitySearchText == query.normalizedFacilitySearchText
    }
}

private extension String {
    nonisolated var normalizedFacilitySearchText: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
