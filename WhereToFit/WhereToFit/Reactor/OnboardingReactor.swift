//
//  OnboardingReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import ReactorKit

final class OnboardingReactor: BaseReactor {
    let initialState: State = State(currentStep: .start)
    
    enum Action {
        case nextButtonTapped
        case backButtonTapped
        case retryButtonTapped
    }
    
    enum Mutation {
        case setStep(OnboardingStep)
    }
    
    struct State {
        var currentStep: OnboardingStep
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .nextButtonTapped:
            guard let nextStep = currentState.currentStep.next else {
                return .empty()
            }
            
            return .just(.setStep(nextStep))
            
        case .backButtonTapped:
            guard let previousStep = currentState.currentStep.previous else {
                return .empty()
            }
            
            return .just(.setStep(previousStep))
            
        case .retryButtonTapped:
            return .just(.setStep(.start))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setStep(let step):
            newState.currentStep = step
        }
        
        return newState
    }
}
