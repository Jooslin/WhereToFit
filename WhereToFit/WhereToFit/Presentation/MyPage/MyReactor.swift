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
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let fetchUserLocationsUseCase: FetchUserLocationsUseCase

    init(
        fetchICloudSyncStatusUseCase: FetchICloudSyncStatusUseCase,
        fetchUserProfileUseCase: FetchUserProfileUseCase,
        fetchUserLocationsUseCase: FetchUserLocationsUseCase
    ) {
        self.fetchICloudSyncStatusUseCase = fetchICloudSyncStatusUseCase
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.fetchUserLocationsUseCase = fetchUserLocationsUseCase
    }

    enum Action {
        case viewWillAppear
    }

    enum Mutation {
        case setICloudSyncStatus(ICloudSyncStatus)
        case setProfileSummary(ProfileSummary)
    }

    struct State {
        var iCloudSyncStatus: ICloudSyncStatus = .needsAttention
        var profileSummary = ProfileSummary(nickname: "사용자", homeAddress: nil)
    }

    struct ProfileSummary: Equatable {
        let nickname: String
        let homeAddress: String?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .merge([
                fetchICloudSyncStatusUseCase.execute()
                    .asObservable()
                    .map(Mutation.setICloudSyncStatus),
                fetchProfileSummary()
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setICloudSyncStatus(let status):
            newState.iCloudSyncStatus = status
        case .setProfileSummary(let summary):
            newState.profileSummary = summary
        }

        return newState
    }
}

private extension MyReactor {
    func fetchProfileSummary() -> Observable<Mutation> {
        fetchUserProfileUseCase.execute()
            .flatMap { [fetchUserLocationsUseCase] profile -> Single<ProfileSummary> in
                guard let profile else {
                    return .just(ProfileSummary(nickname: "사용자", homeAddress: nil))
                }

                return fetchUserLocationsUseCase.execute(userProfileID: profile.id)
                    .map { locations in
                        let homeAddress = locations.first { $0.kind == .home }?.address
                        return ProfileSummary(
                            nickname: profile.nickname,
                            homeAddress: homeAddress
                        )
                    }
            }
            .asObservable()
            .map(Mutation.setProfileSummary)
            .catch { _ in .empty() }
    }
}
