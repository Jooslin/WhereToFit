//
//  MyReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/2/26.
//
import ReactorKit
import RxSwift

final class MyReactor: BaseReactor {
    let initialState = State()
    private let fetchICloudSyncStatusUseCase: FetchICloudSyncStatusUseCase

    init(fetchICloudSyncStatusUseCase: FetchICloudSyncStatusUseCase) {
        self.fetchICloudSyncStatusUseCase = fetchICloudSyncStatusUseCase
    }

    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setICloudSyncStatus(ICloudSyncStatus)
    }

    struct State {
        var iCloudSyncStatus: ICloudSyncStatus = .needsAttention
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return fetchICloudSyncStatusUseCase.execute()
                .asObservable()
                .map(Mutation.setICloudSyncStatus)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setICloudSyncStatus(let status):
            newState.iCloudSyncStatus = status
        }

        return newState
    }
}
