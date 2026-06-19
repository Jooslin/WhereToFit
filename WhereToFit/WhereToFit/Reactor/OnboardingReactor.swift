//
//  OnboardingReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import ReactorKit
import Foundation
import OSLog

final class OnboardingReactor: BaseReactor {
    private let logger = Logger.init(subsystem: "WhereToFit", category: "OnboardingReactor")
    let initialState: State = State(currentStep: .start)
    
    enum Action {
        // 이동
        case nextButtonTapped
        case backButtonTapped
        case retryButtonTapped
        
        // 데이터 업데이트
        case updateNickname(String)
        case updateBirthday(String)
        case updateGender(String)
        case updateAddress(String)
        case updateWeight(String)
        case updateHeight(String)
    }
    
    enum Mutation {
        case setStep(OnboardingStep)
        case setNickname(String)
        case setBirthday(Date)
        case setGender(UserGender)
        case setLocation
        case setWeight
        case setHeight
        
        case setError(title: String, message: String)
        case setIsNextButtonEnabled(Bool)
    }
    
    struct State {
        var currentStep: OnboardingStep
        var nickname: String?
        var birthday: Date?
        var gender: UserGender?
        var location: UserLocation?
        var weight: Double?
        var height: Double?
        
        @Pulse var error: (String, String)?
        var isNextButtonEnabled: Bool = false
    }
    
    //MARK: Properties & Initializer
    private let dateService: DateService
    
    init(dateService: DateService) {
        self.dateService = dateService
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
            
        case .updateNickname(let nickname):
            return .just(.setNickname(nickname))
            
        case .updateBirthday(let stringBirthday):
            return makeBirthdayData(from: stringBirthday)
            
        case .updateGender(let stringGender):
            guard let gender = UserGender(rawValue: stringGender) else {
                logger.error("invalid gender")
                return .empty()
            }
            
            return .just(.setGender(gender))
            
        case .updateAddress(let stringAddress):
            return makeLocationData(from: stringAddress)
            
        case .updateWeight(let stringWeight):
            return makeWeightData(from: stringWeight)
            
        case .updateHeight(let stringHeight):
            return makeHeightData(from: stringHeight)
        }
        
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setStep(let step):
            newState.currentStep = step
        case .setNickname(let nickname):
            newState.nickname = nickname
        case .setBirthday(let birthday):
            newState.birthday = birthday
        case .setGender(let gender):
            newState.gender = gender
        case .setLocation:
            newState.location = nil
        case .setWeight:
            newState.weight = nil
        case .setHeight:
            newState.height = nil
            
        case .setError(title: let title, message: let message):
            newState.error = (title, message)
        case .setIsNextButtonEnabled(let isEnabled):
            newState.isNextButtonEnabled = isEnabled
        }
        
        return newState
    }
}

extension OnboardingReactor {
    private func makeBirthdayData(from string: String) -> Observable<Mutation> {
        
        .just(.setBirthday(Date()))
    }
    
    private func makeLocationData(from string: String) -> Observable<Mutation> {
        
        .just(.setLocation)
    }
    
    private func makeWeightData(from string: String) -> Observable<Mutation> {
        .just(.setWeight)
    }
    
    private func makeHeightData(from string: String) -> Observable<Mutation> {
        .just(.setHeight)
    }
    
    private func isNextButtonEnabled() -> Observable<Mutation> {
        .just(.setIsNextButtonEnabled(true))
    }
}
