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
        case updateExerciseExperience(String)
        case updateExerciseGoal(String)
        case togglePreferredSportsCategory(String)
        case toggleDiscomfortBodyPart(String)
        case updateUsesPublicFacility(Bool)
    }
    
    enum Mutation {
        case setStep(OnboardingStep)
        case setNickname(String)
        case setBirthday(Date?)
        case setGender(UserGender)
        case setLocation
        case setWeight
        case setHeight
        case setExerciseExperience(ExerciseExperience)
        case setExerciseGoal(ExerciseGoal)
        case togglePreferredSportsCategory(SportsCategory)
        case toggleDiscomfortBodyPart(DiscomfortBodyPart)
        case setUsesPublicFacility(Bool)
        
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
        var exerciseExperience: ExerciseExperience?
        var exerciseGoal: ExerciseGoal?
        var preferredSportsCategoryRawValues: [String] = []
        var discomfortBodyParts: [DiscomfortBodyPart] = []
        var usesPublicFacility: Bool = false
        
        @Pulse var error: (String, String)?
        var isNextButtonEnabled: Bool = false
    }
    
    //MARK: Properties & Initializer
    private let dateService: DateService
    
    init(dateService: DateService = DateService()) {
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
            
        case .updateExerciseExperience(let stringExperience):
            guard let experience = ExerciseExperience(rawValue: stringExperience) else {
                logger.error("invalid exercise experience")
                return .empty()
            }
            
            return .just(.setExerciseExperience(experience))
            
        case .updateExerciseGoal(let stringGoal):
            guard let goal = ExerciseGoal(rawValue: stringGoal) else {
                logger.error("invalid exercise goal")
                return .empty()
            }
            
            return .just(.setExerciseGoal(goal))
            
        case .togglePreferredSportsCategory(let stringCategory):
            guard let category = SportsCategory(rawValue: stringCategory) else {
                logger.error("invalid preferred sports category")
                return .empty()
            }
            
            return .just(.togglePreferredSportsCategory(category))
            
        case .toggleDiscomfortBodyPart(let stringBodyPart):
            guard let bodyPart = DiscomfortBodyPart(rawValue: stringBodyPart) else {
                logger.error("invalid discomfort body part")
                return .empty()
            }
            
            return .just(.toggleDiscomfortBodyPart(bodyPart))
            
        case .updateUsesPublicFacility(let usesPublicFacility):
            return .just(.setUsesPublicFacility(usesPublicFacility))
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
        case .setExerciseExperience(let experience):
            newState.exerciseExperience = experience
        case .setExerciseGoal(let goal):
            newState.exerciseGoal = goal
        case .togglePreferredSportsCategory(let category):
            if newState.preferredSportsCategoryRawValues.contains(category.rawValue) {
                newState.preferredSportsCategoryRawValues.removeAll { $0 == category.rawValue }
            } else {
                newState.preferredSportsCategoryRawValues.append(category.rawValue)
            }
        case .toggleDiscomfortBodyPart(let bodyPart):
            if newState.discomfortBodyParts.contains(bodyPart) {
                newState.discomfortBodyParts.removeAll { $0 == bodyPart }
            } else {
                newState.discomfortBodyParts.append(bodyPart)
            }
        case .setUsesPublicFacility(let usesPublicFacility):
            newState.usesPublicFacility = usesPublicFacility
            
        case .setError(title: let title, message: let message):
            newState.error = (title, message)
        case .setIsNextButtonEnabled(let isEnabled):
            newState.isNextButtonEnabled = isEnabled
        }
        
        if newState.currentStep == .personalInfo {
            newState.isNextButtonEnabled = Self.isPersonalInfoNextButtonEnabled(newState)
        }
        
        return newState
    }
}

extension OnboardingReactor {
    private func makeBirthdayData(from string: String) -> Observable<Mutation> {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedString.isEmpty == false else {
            return .just(.setBirthday(nil))
        }
        
        return .just(.setBirthday(Date()))
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
    
    private static func isPersonalInfoNextButtonEnabled(_ state: State) -> Bool {
        state.nickname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        && state.birthday != nil
        && state.gender != nil
    }
}
