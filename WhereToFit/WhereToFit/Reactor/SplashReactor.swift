//
//  SplashReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import ReactorKit

final class SplashReactor: BaseReactor {
    let initialState = State()
    
    enum Action {
        case viewDidLoad
    }
    
    enum Mutation {
        case setDestination(AppStep)
    }
    
    struct State {
        var destination: AppStep?
    }
    
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let preloadSportRecommendationRulesUseCase: PreloadSportRecommendationRulesUseCase
    
    init(
        fetchUserProfileUseCase: FetchUserProfileUseCase,
        preloadSportRecommendationRulesUseCase: PreloadSportRecommendationRulesUseCase
    ) {
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.preloadSportRecommendationRulesUseCase = preloadSportRecommendationRulesUseCase
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let profile = fetchUserProfileUseCase.execute()
                .catch { _ in .just(nil) }
            let preloadRules = preloadSportRecommendationRulesUseCase.execute()
                .catch { _ in .just(()) }
            
            return Single.zip(profile, preloadRules)
                .map { profile, _ in
                    Mutation.setDestination(profile == nil ? .onboarding : .main)
                }
                .asObservable()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setDestination(let step):
            newState.destination = step
        }
        
        return newState
    }
}
