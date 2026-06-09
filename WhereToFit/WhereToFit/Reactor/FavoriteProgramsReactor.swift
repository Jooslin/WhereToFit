//
//  FavoriteProgramsReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxSwift

final class FavoriteProgramsReactor: BaseReactor {
    let initialState = State(
        selectedTab: .facility,
        items: FavoriteTab.facility.items
    )

    enum FavoriteTab {
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

        var items: [FavoriteItem] {
            switch self {
            case .facility:
                return [
                    FavoriteItem(name: "올림픽수영장", schedule: "월-금 06:00-23:00", distance: "거리 1.0km", price: "원~"),
                    FavoriteItem(name: "곰두리체육문화회관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
                    FavoriteItem(name: "송파여성체육문화회관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
                    FavoriteItem(name: "송파배드민턴체육관", schedule: "요일 00:00-00:00", distance: "거리 0.0km", price: "원~")
                ]
            case .program:
                return [
                    FavoriteItem(name: "수영 초보 클래스", schedule: "시설  요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
                    FavoriteItem(name: "저녁 요가", schedule: "시설  요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
                    FavoriteItem(name: "초급 필라테스", schedule: "시설  요일 00:00-00:00", distance: "거리 0.0km", price: "원~"),
                    FavoriteItem(name: "배드민턴 2:1 듀엣", schedule: "시설  요일 00:00-00:00", distance: "거리 0.0km", price: "원~")
                ]
            }
        }
    }

    struct FavoriteItem: Equatable {
        let name: String
        let schedule: String
        let distance: String
        let price: String
    }

    enum Action {
        case selectTab(FavoriteTab)
    }

    enum Mutation {
        case setTab(FavoriteTab)
    }

    struct State {
        var selectedTab: FavoriteTab
        var items: [FavoriteItem]
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectTab(let tab):
            return .just(.setTab(tab))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setTab(let tab):
            newState.selectedTab = tab
            newState.items = tab.items
        }

        return newState
    }
}
