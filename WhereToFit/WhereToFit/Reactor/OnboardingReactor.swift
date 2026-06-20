//
//  OnboardingReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import ReactorKit
import Foundation
import OSLog
import RxSwift

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
        
        // 저장
        case save
    }

    enum Mutation {
        case setStep(OnboardingStep)
        case setNickname(String)
        case setBirthday(Date?)
        case setGender(UserGender)
        case setAddress(String?)
        case setWeight(Double?)
        case setHeight(Double?)
        case setExerciseExperience(ExerciseExperience)
        case setExerciseGoal(ExerciseGoal)
        case togglePreferredSportsCategory(SportsCategory)
        case toggleDiscomfortBodyPart(DiscomfortBodyPart)
        case setUsesPublicFacility(Bool)

        case setError(title: String, message: String)
        case setSaveResult(SaveResult)
        case setIsSaving(Bool)
        case setIsNextButtonEnabled(Bool)
    }

    enum SaveResult: Equatable {
        case success
        case successWithLocationWarning
    }

    struct State {
        var currentStep: OnboardingStep
        var nickname: String?
        var birthday: Date?
        var gender: UserGender?
        var address: String?
        var weight: Double?
        var height: Double?
        var exerciseExperience: ExerciseExperience?
        var exerciseGoal: ExerciseGoal?
        var preferredSportsCategories: [SportsCategory] = []
        var discomfortBodyParts: [DiscomfortBodyPart] = []
        var usesPublicFacility: Bool = false

        @Pulse var error: (String, String)?
        @Pulse var saveResult: SaveResult?
        var isSaving: Bool = false
        var isNextButtonEnabled: Bool = false
    }

    //MARK: Properties & Initializer
    private let validatePersonalInfoUseCase: ValidateOnboardingPersonalInfoUseCase
    private let addressCoordinateUseCase: AddressCoordinateUseCase
    private let upsertUserProfileUseCase: UpsertUserProfileUseCase
    private let addUserLocationUseCase: AddUserLocationUseCase

    init(
        dateService: DateService,
        addressCoordinateUseCase: AddressCoordinateUseCase,
        upsertUserProfileUseCase: UpsertUserProfileUseCase,
        addUserLocationUseCase: AddUserLocationUseCase
    ) {
        self.validatePersonalInfoUseCase = ValidateOnboardingPersonalInfoUseCase(dateService: dateService)
        self.addressCoordinateUseCase = addressCoordinateUseCase
        self.upsertUserProfileUseCase = upsertUserProfileUseCase
        self.addUserLocationUseCase = addUserLocationUseCase
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
            return updateAddressData(from: stringAddress)

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
            
        case .save:
            return saveOnboardingData()
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
        case .setAddress(let address):
            newState.address = address
        case .setWeight(let weight):
            newState.weight = weight
        case .setHeight(let height):
            newState.height = height
        case .setExerciseExperience(let experience):
            newState.exerciseExperience = experience
        case .setExerciseGoal(let goal):
            newState.exerciseGoal = goal
        case .togglePreferredSportsCategory(let category):
            if newState.preferredSportsCategories.contains(category) {
                newState.preferredSportsCategories.removeAll { $0 == category }
            } else {
                newState.preferredSportsCategories.append(category)
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
        case .setSaveResult(let result):
            newState.saveResult = result
        case .setIsSaving(let isSaving):
            newState.isSaving = isSaving
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
        switch validatePersonalInfoUseCase.validateBirthday(string) {
        case .success(let birthday):
            return .just(.setBirthday(birthday))
        case .failure(let error):
            return .from([
                .setBirthday(nil),
                .setError(title: error.title, message: error.message)
            ])
        }
    }

    private func updateAddressData(from string: String) -> Observable<Mutation> {
#if DEBUG
        return .concat([
            .just(.setAddress(string)),
            checkAddressCoordinateForDebug(address: string)
        ])
#else
        return .just(.setAddress(string))
#endif
    }

    private func makeWeightData(from string: String) -> Observable<Mutation> {
        switch validatePersonalInfoUseCase.validateWeight(string) {
        case .success(let weight):
            return .just(.setWeight(weight))
        case .failure(let error):
            return .from([
                .setWeight(nil),
                .setError(title: error.title, message: error.message)
            ])
        }
    }

    private func makeHeightData(from string: String) -> Observable<Mutation> {
        switch validatePersonalInfoUseCase.validateHeight(string) {
        case .success(let height):
            return .just(.setHeight(height))
        case .failure(let error):
            return .from([
                .setHeight(nil),
                .setError(title: error.title, message: error.message)
            ])
        }
    }

    private static func isPersonalInfoNextButtonEnabled(_ state: State) -> Bool {
        state.nickname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        && state.birthday != nil
        && state.gender != nil
    }

#if DEBUG
    private func checkAddressCoordinateForDebug(address: String) -> Observable<Mutation> {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAddress.isEmpty == false else {
            return .empty()
        }

        return addressCoordinateUseCase.execute(address: trimmedAddress)
            .asObservable()
            .map { coordinate -> Mutation in
                guard let coordinate else {
                    return .setError(title: "좌표 확인", message: "현재 위치의 좌표를 찾지 못했어요.")
                }

                return .setError(
                    title: "좌표 확인",
                    message: "위도: \(coordinate.latitude)\n경도: \(coordinate.longitude)"
                )
            }
            .catch { _ in
                .just(.setError(title: "좌표 확인", message: "좌표 검색 요청에 실패했어요."))
            }
    }
#endif

    private func saveOnboardingData() -> Observable<Mutation> {
        guard currentState.isSaving == false else {
            return .empty()
        }

        guard let profileInput = makeUserProfileInput() else {
            return .just(.setError(title: "저장 실패", message: "필수 정보를 확인해주세요."))
        }

        let address = currentState.address?.trimmingCharacters(in: .whitespacesAndNewlines)
        let saveResult = saveProfileAndLocation(profileInput: profileInput, address: address)
            .asObservable()
            .map { result in
                switch result {
                case .success:
                    return Mutation.setStep(.end)
                case .successWithLocationWarning:
                    return Mutation.setSaveResult(result)
                }
            }
            .catch { _ in
                .just(.setError(title: "저장 실패", message: "온보딩 정보를 저장하지 못했어요."))
            }

        return .concat([
            .just(.setIsSaving(true)),
            saveResult,
            .just(.setIsSaving(false))
        ])
    }

    private func makeUserProfileInput() -> UpsertUserProfileUseCase.Input? {
        guard let nickname = currentState.nickname,
              let birthDate = currentState.birthday,
              let gender = currentState.gender else {
            return nil
        }

        return UpsertUserProfileUseCase.Input(
            nickname: nickname,
            birthDate: birthDate,
            gender: gender,
            height: currentState.height,
            initialWeight: currentState.weight,
            exerciseExperience: currentState.exerciseExperience,
            exerciseGoal: currentState.exerciseGoal,
            preferredSportsCategories: currentState.preferredSportsCategories,
            discomfortBodyParts: currentState.discomfortBodyParts,
            usesPublicFacility: currentState.usesPublicFacility
        )
    }

    private func saveProfileAndLocation(
        profileInput: UpsertUserProfileUseCase.Input,
        address: String?
    ) -> Single<SaveResult> {
        upsertUserProfileUseCase.execute(profileInput)
            .flatMap { [addressCoordinateUseCase, addUserLocationUseCase] profile -> Single<SaveResult> in
                guard let address,
                      address.isEmpty == false else {
                    return .just(.success)
                }

                return addressCoordinateUseCase.execute(address: address)
                    .flatMap { coordinate -> Single<SaveResult> in
                        guard let coordinate else {
                            return .just(.successWithLocationWarning)
                        }

                        let locationInput = AddUserLocationUseCase.Input(
                            userProfileID: profile.id,
                            name: address,
                            address: address,
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            isSelected: true,
                            kind: .home
                        )

                        return addUserLocationUseCase.execute(locationInput)
                            .map { _ -> SaveResult in .success }
                            .catchAndReturn(.successWithLocationWarning)
                    }
                    .catchAndReturn(.successWithLocationWarning)
            }
    }
}
