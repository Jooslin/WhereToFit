//
//  MapReactor.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import Foundation
import ReactorKit
import RxSwift

final class MapReactor: BaseReactor {
    enum Action {
        case viewDidLoad
        case loadProgramsForFacilities([String])
        case searchTextChanged(String)
        case toggleAIRecommendation
        case applyFilter(FacilityFilter)
        case toggleCategory(FacilityCategory?)
        case toggleDay(DayOfWeek?)
        case toggleTimeSlot(TimeSlot?)
        case selectFacility(String?)
        case refreshFavorites
        case setFavorite(FavoriteTargetKey, Bool)
        case tapReservation(String)
        case updateVisibleFacilityIDs([String])
        case setSearchErrorMessage(String?)
        case didOpenReservationURL
    }

    enum Mutation {
        case setLoading(Bool)
        case setProgramLoading(Bool)
        case setAllMarkerFacilities([FitnessFacility])
        case setMarkerFacilities([FitnessFacility])
        case setAllFacilities([FitnessFacility])
        case setFacilities([FitnessFacility])
        case setSearchText(String)
        case setFilter(FacilityFilter)
        case setSelectedFacilityID(String?)
        case setFavoriteKeys(Set<FavoriteTargetKey>)
        case setFavorite(FavoriteTargetKey, Bool)
        case setUserProfileExists(Bool)
        case requestAIOnboarding
        case setReservationURLToOpen(URL?)
        case setVisibleFacilityIDs(Set<String>)
        case setSearchErrorMessage(String?)
        case setErrorMessage(String?)
    }

    struct State {
        var allMarkerFacilities: [FitnessFacility] = []
        var markerFacilities: [FitnessFacility] = []
        var allFacilities: [FitnessFacility] = []
        var facilities: [FitnessFacility] = []
        var searchText = ""
        var filter = FacilityFilter.empty
        var selectedFacilityID: String?
        var reservationURLToOpen: URL?
        var hasUserProfile = false
        @Pulse var shouldOpenOnboardingForAIRecommendation = false
        var visibleFacilityIDs = Set<String>()
        var searchErrorMessage: String?
        var isLoading = false
        var isProgramLoading = false
        var errorMessage: String?

        var emptyStateMessage: String {
            if let searchErrorMessage {
                return searchErrorMessage
            }

            if let errorMessage {
                return errorMessage
            }

            // VC는 지도 bounds만 알고 있으므로, 보이는 시설 id만 전달하고 문구 판단은 Reactor에서 처리합니다.
            if visibleFacilityIDs.isEmpty {
                return "주변에 시설, 프로그램이 없습니다."
            }

            return "조건에 맞는 프로그램이 없습니다."
        }

        var hasEmptyStateError: Bool {
            searchErrorMessage != nil || errorMessage != nil
        }

        var selectedFacility: FitnessFacility? {
            guard let selectedFacilityID else { return nil }
            return facilities.first { $0.id == selectedFacilityID }
                ?? markerFacilities.first { $0.id == selectedFacilityID }
        }

        var isNaverMapKeyConfigured: Bool {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "NMFNcpKeyId") as? String else {
                return false
            }

            return key.isEmpty == false
                && key.contains("$(") == false
                && key != "YOUR_NCP_KEY_ID_HERE"
        }
    }

    let initialState = State()
    private let fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase
    private let fetchFavoritesUseCase: FetchFavoritesUseCase
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private var favoriteKeys = Set<FavoriteTargetKey>()
    private var loadedProgramFacilityIDs = Set<String>()
    private var loadingProgramFacilityIDs = Set<String>()

    init(
        fetchNearbyFacilitiesUseCase: FetchNearbyFacilitiesUseCase,
        fetchFavoritesUseCase: FetchFavoritesUseCase,
        fetchUserProfileUseCase: FetchUserProfileUseCase = FetchUserProfileUseCase(
            repository: CoreDataUserProfileRepository()
        )
    ) {
        self.fetchNearbyFacilitiesUseCase = fetchNearbyFacilitiesUseCase
        self.fetchFavoritesUseCase = fetchFavoritesUseCase
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            loadedProgramFacilityIDs.removeAll()
            loadingProgramFacilityIDs.removeAll()

            return .concat([
                .just(.setLoading(true)),
                fetchUserProfileUseCase.execute()
                    .asObservable()
                    .catch { _ in .just(nil) }
                    .flatMap { [weak self] profile -> Observable<Mutation> in
                        guard let self else { return .empty() }
                        let hasUserProfile = profile != nil
                        var initialFilter = self.currentState.filter
                        initialFilter.isAIRecommendationEnabled = hasUserProfile

                        let fetchFacilities = self.fetchFavoriteKeys()
                            .flatMap { [weak self] favoriteKeys -> Observable<Mutation> in
                                guard let self else { return .empty() }
                                self.favoriteKeys = favoriteKeys

                                return self.fetchNearbyFacilitiesUseCase.fetch()
                                    .asObservable()
                                    .flatMap { [weak self] dataSet -> Observable<Mutation> in
                                        guard let self else { return .empty() }
                                        let allMarkerFacilities = self.applyFavoriteState(to: dataSet.markerFacilities)
                                        let allFacilities = self.applyFavoriteState(to: dataSet.programFacilities)
                                        let filteredFacilities = self.filterFacilities(
                                            allFacilities,
                                            searchText: self.currentState.searchText,
                                            filter: initialFilter
                                        )
                                        let markerFacilities = self.filterMarkerFacilities(
                                            allMarkerFacilities: allMarkerFacilities,
                                            allFacilities: allFacilities,
                                            searchText: self.currentState.searchText,
                                            filter: initialFilter
                                        )
                                        return .from([
                                            .setAllMarkerFacilities(allMarkerFacilities),
                                            .setMarkerFacilities(markerFacilities),
                                            .setAllFacilities(allFacilities),
                                            .setFacilities(filteredFacilities),
                                            .setErrorMessage(nil)
                                        ])
                                    }
                                    .catch { error in
                                        .from([
                                            .setAllMarkerFacilities([]),
                                            .setMarkerFacilities([]),
                                            .setAllFacilities([]),
                                            .setFacilities([]),
                                            .setErrorMessage(error.localizedDescription)
                                        ])
                                    }
                            }

                        return .concat([
                            .from([
                                .setUserProfileExists(hasUserProfile),
                                .setFilter(initialFilter)
                            ]),
                            fetchFacilities
                        ])
                    },
                .just(.setLoading(false))
            ])

        case let .loadProgramsForFacilities(facilityIDs):
            let requestedIDs = Set(facilityIDs)
            let facilityIDsToLoad = Array(
                requestedIDs
                    .subtracting(loadedProgramFacilityIDs)
                    .subtracting(loadingProgramFacilityIDs)
            )

            guard facilityIDsToLoad.isEmpty == false else {
                return .empty()
            }

            let markerFacilities = currentState.allMarkerFacilities.filter { facility in
                guard let sourceFacilityID = facility.sourceFacilityID else { return false }
                return facilityIDsToLoad.contains(sourceFacilityID)
            }

            guard markerFacilities.isEmpty == false else {
                return .empty()
            }

            let loadingIDs = Set(facilityIDsToLoad)
            loadingProgramFacilityIDs.formUnion(loadingIDs)

            return .concat([
                .just(.setProgramLoading(true)),
                fetchNearbyFacilitiesUseCase.fetchPrograms(for: markerFacilities)
                    .asObservable()
                    .flatMap { [weak self] facilities -> Observable<Mutation> in
                        guard let self else { return .empty() }
                        self.loadingProgramFacilityIDs.subtract(loadingIDs)
                        self.loadedProgramFacilityIDs.formUnion(loadingIDs)

                        let existingIDs = Set(self.currentState.allFacilities.map(\.id))
                        let newFacilities = facilities.filter { existingIDs.contains($0.id) == false }
                        let allFacilities = self.applyFavoriteState(to: self.currentState.allFacilities + newFacilities)
                        let filteredFacilities = self.filterFacilities(
                            allFacilities,
                            searchText: self.currentState.searchText,
                            filter: self.currentState.filter
                        )
                        let markerFacilities = self.filterMarkerFacilities(
                            allMarkerFacilities: self.currentState.allMarkerFacilities,
                            allFacilities: allFacilities,
                            searchText: self.currentState.searchText,
                            filter: self.currentState.filter
                        )

                        return .from([
                            .setAllFacilities(allFacilities),
                            .setMarkerFacilities(markerFacilities),
                            .setFacilities(filteredFacilities),
                            .setProgramLoading(self.loadingProgramFacilityIDs.isEmpty == false),
                            .setErrorMessage(nil)
                        ])
                    }
                    .catch { [weak self] _ in
                        self?.loadingProgramFacilityIDs.subtract(loadingIDs)
                        let isStillLoading = self?.loadingProgramFacilityIDs.isEmpty == false
                        return .just(.setProgramLoading(isStillLoading))
                    }
            ])

        case let .searchTextChanged(searchText):
            let facilities = filterFacilities(
                currentState.allFacilities,
                searchText: searchText,
                filter: currentState.filter
            )
            let markerFacilities = filterMarkerFacilities(
                allMarkerFacilities: currentState.allMarkerFacilities,
                allFacilities: currentState.allFacilities,
                searchText: searchText,
                filter: currentState.filter
            )
            return .concat([
                .just(.setSearchText(searchText)),
                .just(.setSearchErrorMessage(nil)),
                .just(.setMarkerFacilities(markerFacilities)),
                .just(.setFacilities(facilities)),
                .just(.setSelectedFacilityID(nil))
            ])

        case .toggleAIRecommendation:
            guard currentState.hasUserProfile else {
                var filter = currentState.filter
                filter.isAIRecommendationEnabled = false
                return .concat([
                    updateFilter(filter),
                    .just(.requestAIOnboarding)
                ])
            }

            var filter = currentState.filter
            filter.isAIRecommendationEnabled.toggle()
            return updateFilter(filter)

        case let .applyFilter(filter):
            return updateFilter(filter)

        case let .toggleCategory(category):
            var filter = currentState.filter
            if let category {
                if filter.categories.contains(category) {
                    filter.categories.remove(category)
                } else {
                    filter.categories.insert(category)
                }

                if filter.categories.count == FacilityCategory.allCases.count {
                    filter.categories.removeAll()
                }
            } else {
                filter.categories.removeAll()
            }
            return updateFilter(filter)

        case let .toggleDay(day):
            var filter = currentState.filter
            if let day {
                if filter.days.contains(day) {
                    filter.days.remove(day)
                } else {
                    filter.days.insert(day)
                }

                if filter.days.count == DayOfWeek.allCases.count {
                    filter.days.removeAll()
                }
            } else {
                filter.days.removeAll()
            }
            return updateFilter(filter)

        case let .toggleTimeSlot(timeSlot):
            var filter = currentState.filter
            if let timeSlot {
                if filter.timeSlots.contains(timeSlot) {
                    filter.timeSlots.remove(timeSlot)
                } else {
                    filter.timeSlots.insert(timeSlot)
                }

                if filter.timeSlots.count == TimeSlot.allCases.count {
                    filter.timeSlots.removeAll()
                }
            } else {
                filter.timeSlots.removeAll()
            }
            return updateFilter(filter)

        case let .selectFacility(id):
            return .concat([
                .just(.setSelectedFacilityID(id)),
                .just(.setSearchErrorMessage(nil))
            ])

        case .refreshFavorites:
            return fetchFavoriteKeys()
                .do(onNext: { [weak self] favoriteKeys in
                    self?.favoriteKeys = favoriteKeys
                })
                .map(Mutation.setFavoriteKeys)

        case let .setFavorite(key, isFavorite):
            if isFavorite {
                favoriteKeys.insert(key)
            } else {
                favoriteKeys.remove(key)
            }
            return .just(.setFavorite(key, isFavorite))

        case let .tapReservation(id):
            let url = currentState.facilities.first { $0.id == id }?.reservationURL
                ?? currentState.markerFacilities.first { $0.id == id }?.reservationURL
            return .just(.setReservationURLToOpen(url))

        case let .updateVisibleFacilityIDs(ids):
            let visibleFacilityIDs = Set(ids)
            guard visibleFacilityIDs != currentState.visibleFacilityIDs else {
                return .empty()
            }
            return .just(.setVisibleFacilityIDs(visibleFacilityIDs))

        case let .setSearchErrorMessage(message):
            return .just(.setSearchErrorMessage(message))

        case .didOpenReservationURL:
            return .just(.setReservationURLToOpen(nil))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case let .setLoading(isLoading):
            newState.isLoading = isLoading

        case let .setProgramLoading(isLoading):
            newState.isProgramLoading = isLoading

        case let .setAllMarkerFacilities(facilities):
            newState.allMarkerFacilities = facilities

        case let .setMarkerFacilities(facilities):
            newState.markerFacilities = facilities

        case let .setAllFacilities(facilities):
            newState.allFacilities = facilities

        case let .setFacilities(facilities):
            newState.facilities = facilities
            if let selectedFacilityID = newState.selectedFacilityID,
               facilities.contains(where: { $0.id == selectedFacilityID }) == false,
               newState.markerFacilities.contains(where: { $0.id == selectedFacilityID }) == false {
                newState.selectedFacilityID = nil
            }

        case let .setSearchText(searchText):
            newState.searchText = searchText

        case let .setFilter(filter):
            newState.filter = filter

        case let .setSelectedFacilityID(id):
            newState.selectedFacilityID = id

        case let .setFavoriteKeys(favoriteKeys):
            applyFavoriteKeys(favoriteKeys, to: &newState)

        case let .setFavorite(key, isFavorite):
            updateFavoriteState(key: key, isFavorite: isFavorite, in: &newState)

        case let .setUserProfileExists(hasUserProfile):
            newState.hasUserProfile = hasUserProfile

        case .requestAIOnboarding:
            newState.shouldOpenOnboardingForAIRecommendation = true

        case let .setReservationURLToOpen(url):
            newState.reservationURLToOpen = url

        case let .setVisibleFacilityIDs(ids):
            newState.visibleFacilityIDs = ids

        case let .setSearchErrorMessage(message):
            newState.searchErrorMessage = message

        case let .setErrorMessage(message):
            newState.errorMessage = message
        }

        return newState
    }

    private func fetchFavoriteKeys() -> Observable<Set<FavoriteTargetKey>> {
        fetchFavoritesUseCase.execute()
            .map { favorites in
                Set(favorites.map(FavoriteTargetKey.init(favorite:)))
            }
            .asObservable()
            .catch { _ in .just(Set<FavoriteTargetKey>()) }
    }

    private func updateFilter(_ filter: FacilityFilter) -> Observable<Mutation> {
        let facilities = filterFacilities(
            currentState.allFacilities,
            searchText: currentState.searchText,
            filter: filter
        )
        let markerFacilities = filterMarkerFacilities(
            allMarkerFacilities: currentState.allMarkerFacilities,
            allFacilities: currentState.allFacilities,
            searchText: currentState.searchText,
            filter: filter
        )
        return .concat([
            .just(.setFilter(filter)),
            .just(.setMarkerFacilities(markerFacilities)),
            .just(.setFacilities(facilities)),
            .just(.setSelectedFacilityID(nil))
        ])
    }

    private func filterFacilities(
        _ facilities: [FitnessFacility],
        searchText: String,
        filter: FacilityFilter
    ) -> [FitnessFacility] {
        fetchNearbyFacilitiesUseCase.filter(
            facilities: facilities,
            searchText: searchText,
            filter: filter
        )
        .map { facility in
            applyFavoriteState(to: facility)
        }
    }

    private func filterMarkerFacilities(
        allMarkerFacilities: [FitnessFacility],
        allFacilities: [FitnessFacility],
        searchText: String,
        filter: FacilityFilter
    ) -> [FitnessFacility] {
        let filteredCandidates = filterFacilities(
            allMarkerFacilities + allFacilities,
            searchText: searchText,
            filter: filter
        )
        let matchingSourceIDs = Set(filteredCandidates.map { $0.sourceFacilityID ?? $0.id })

        return allMarkerFacilities
            .filter { facility in
                matchingSourceIDs.contains(facility.sourceFacilityID ?? facility.id)
            }
            .map { facility in
                applyFavoriteState(to: facility)
            }
    }

    private func applyFavoriteState(to facilities: [FitnessFacility]) -> [FitnessFacility] {
        applyFavoriteState(to: facilities, favoriteKeys: favoriteKeys)
    }

    private func applyFavoriteState(
        to facilities: [FitnessFacility],
        favoriteKeys: Set<FavoriteTargetKey>
    ) -> [FitnessFacility] {
        facilities.map { facility in
            applyFavoriteState(to: facility, favoriteKeys: favoriteKeys)
        }
    }

    private func applyFavoriteState(to facility: FitnessFacility) -> FitnessFacility {
        applyFavoriteState(to: facility, favoriteKeys: favoriteKeys)
    }

    private func applyFavoriteKeys(
        _ favoriteKeys: Set<FavoriteTargetKey>,
        to state: inout State
    ) {
        state.allMarkerFacilities = applyFavoriteState(to: state.allMarkerFacilities, favoriteKeys: favoriteKeys)
        state.markerFacilities = applyFavoriteState(to: state.markerFacilities, favoriteKeys: favoriteKeys)
        state.allFacilities = applyFavoriteState(to: state.allFacilities, favoriteKeys: favoriteKeys)
        state.facilities = applyFavoriteState(to: state.facilities, favoriteKeys: favoriteKeys)
    }

    private func applyFavoriteState(
        to facility: FitnessFacility,
        favoriteKeys: Set<FavoriteTargetKey>
    ) -> FitnessFacility {
        var updatedFacility = facility
        updatedFacility.isFavorite = favoriteKeys.contains(FavoriteTargetKey(facility: facility))
        return updatedFacility
    }

    private func updateFavoriteState(
        key: FavoriteTargetKey,
        isFavorite: Bool,
        in state: inout State
    ) {
        state.allMarkerFacilities = updateFavoriteState(in: state.allMarkerFacilities, key: key, isFavorite: isFavorite)
        state.markerFacilities = updateFavoriteState(in: state.markerFacilities, key: key, isFavorite: isFavorite)
        state.allFacilities = updateFavoriteState(in: state.allFacilities, key: key, isFavorite: isFavorite)
        state.facilities = updateFavoriteState(in: state.facilities, key: key, isFavorite: isFavorite)
    }

    private func updateFavoriteState(
        in facilities: [FitnessFacility],
        key: FavoriteTargetKey,
        isFavorite: Bool
    ) -> [FitnessFacility] {
        facilities.map { facility in
            var updatedFacility = facility
            if FavoriteTargetKey(facility: facility) == key {
                updatedFacility.isFavorite = isFavorite
            }
            return updatedFacility
        }
    }
}
