//
//  FavoriteProgramsReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import Foundation
import ReactorKit
import RxSwift

final class FavoriteListReactor: BaseReactor {
    let initialState = State(
        selectedTab: .facility,
        items: []
    )
    private let fetchFavoritesUseCase: FetchFavoritesUseCase

    init(fetchFavoritesUseCase: FetchFavoritesUseCase) {
        self.fetchFavoritesUseCase = fetchFavoritesUseCase
    }

    nonisolated enum FavoriteTab {
        case facility
        case program

        init(segmentIndex: Int) {
            self = segmentIndex == 1 ? .program : .facility
        }

        var segmentIndex: Int {
            switch self {
            case .facility:
                return 0
            case .program:
                return 1
            }
        }
    }

    nonisolated struct FavoriteItem: Equatable {
        let name: String
        let facilityLabelText: String?
        let day: String
        let time: String
        let distance: String
        let price: String
    }

    enum Action {
        case viewDidLoad
        case selectTab(FavoriteTab)
    }

    enum Mutation {
        case setTab(FavoriteTab)
        case setItems([FavoriteItem])
    }

    struct State {
        var selectedTab: FavoriteTab
        var items: [FavoriteItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchItems(tab: currentState.selectedTab)

        case .selectTab(let tab):
            return .concat([
                .just(.setTab(tab)),
                fetchItems(tab: tab)
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setTab(let tab):
            newState.selectedTab = tab

        case .setItems(let items):
            newState.items = items
        }

        return newState
    }
}

private extension FavoriteListReactor {
    nonisolated struct FavoriteSnapshot: Decodable {
        let day: String?
        let time: String?
        let distance: String?
        let price: String?
        let facilityLabelText: String?
    }

    func fetchItems(tab: FavoriteTab) -> Observable<Mutation> {
        fetchFavoritesUseCase.execute(targetType: tab.targetType)
            .map { favorites in
                favorites.map(Self.makeFavoriteItem)
            }
            .map(Mutation.setItems)
            .asObservable()
            .catch { _ in .just(.setItems([])) }
    }

    nonisolated static func makeFavoriteItem(_ favorite: Favorite) -> FavoriteItem {
        let snapshot = favorite.snapshotJSON
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode(FavoriteSnapshot.self, from: $0) }

        return FavoriteItem(
            name: favorite.title,
            facilityLabelText: snapshot?.facilityLabelText,
            day: snapshot?.day ?? "요일",
            time: snapshot?.time ?? "00:00-00:00",
            distance: snapshot?.distance ?? "거리 0.0km",
            price: snapshot?.price ?? "원~"
        )
    }
}

private extension FavoriteListReactor.FavoriteTab {
    var targetType: FavoriteTargetType {
        switch self {
        case .facility:
            return .facility
        case .program:
            return .program
        }
    }
}
