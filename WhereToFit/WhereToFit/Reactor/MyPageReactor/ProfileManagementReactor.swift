//
//  ProfileManagementReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/5/26.
//

import Foundation
import ReactorKit
import RxSwift

final class ProfileManagementReactor: BaseReactor {
    let initialState = State()
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let upsertUserProfileUseCase: UpsertUserProfileUseCase
    private let validatePersonalInfoUseCase: ValidateOnboardingPersonalInfoUseCase
    private let birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    init(
        fetchUserProfileUseCase: FetchUserProfileUseCase,
        upsertUserProfileUseCase: UpsertUserProfileUseCase,
        validatePersonalInfoUseCase: ValidateOnboardingPersonalInfoUseCase
    ) {
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.upsertUserProfileUseCase = upsertUserProfileUseCase
        self.validatePersonalInfoUseCase = validatePersonalInfoUseCase
    }

    enum Action {
        case viewDidLoad
        case updateNickname(String)
        case updateBirthday(String)
        case updateGender(UserGender)
        case updateHeight(String)
        case updateWeight(String)
        case save
    }

    enum Mutation {
        case setProfile(UserProfile)
        case setNickname(String)
        case setBirthdayText(String)
        case setBirthDate(Date?)
        case setGender(UserGender)
        case setHeightText(String)
        case setHeight(Double?)
        case setWeightText(String)
        case setWeight(Double?)
        case setIsSaving(Bool)
        case setSaveCompleted
        case setError(String, String)
    }

    struct State {
        var originalProfile: UserProfile?
        var nickname = ""
        var birthdayText = ""
        var birthDate: Date?
        var gender: UserGender = .female
        var heightText = ""
        var height: Double?
        var weightText = ""
        var weight: Double?
        var isSaving = false
        @Pulse var saveCompleted = false
        @Pulse var error: (String, String)?

        var isSaveButtonEnabled: Bool {
            guard isSaving == false,
                  originalProfile != nil,
                  nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                  birthDate != nil,
                  hasChanges else {
                return false
            }

            return true
        }

        private var hasChanges: Bool {
            guard let originalProfile else { return false }

            return nickname.trimmingCharacters(in: .whitespacesAndNewlines) != originalProfile.nickname
                || birthDate != originalProfile.birthDate
                || gender != originalProfile.gender
                || height != originalProfile.height
                || weight != originalProfile.initialWeight
        }
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchUserProfileUseCase.execute()
                .asObservable()
                .compactMap { $0 }
                .map { .setProfile($0) }
                .catch { _ in .just(.setError("프로필 조회 실패", "저장된 프로필 정보를 불러오지 못했어요.")) }

        case .updateNickname(let nickname):
            return .just(.setNickname(nickname))

        case .updateBirthday(let birthday):
            let sanitizedBirthday = ValidateOnboardingPersonalInfoUseCase.sanitizeBirthdayInput(birthday)
            switch validatePersonalInfoUseCase.validateBirthday(sanitizedBirthday) {
            case .success(let birthDate):
                return .from([
                    .setBirthdayText(sanitizedBirthday),
                    .setBirthDate(birthDate)
                ])
            case .failure(let error):
                return .from([
                    .setBirthdayText(sanitizedBirthday),
                    .setBirthDate(nil),
                    .setError(error.title, error.message)
                ])
            }

        case .updateGender(let gender):
            return .just(.setGender(gender))

        case .updateHeight(let height):
            let sanitizedHeight = ValidateOnboardingPersonalInfoUseCase.sanitizeDecimalInput(height)
            switch validatePersonalInfoUseCase.validateHeight(sanitizedHeight) {
            case .success(let height):
                return .from([
                    .setHeightText(sanitizedHeight),
                    .setHeight(height)
                ])
            case .failure(let error):
                return .from([
                    .setHeightText(sanitizedHeight),
                    .setHeight(nil),
                    .setError(error.title, error.message)
                ])
            }

        case .updateWeight(let weight):
            let sanitizedWeight = ValidateOnboardingPersonalInfoUseCase.sanitizeDecimalInput(weight)
            switch validatePersonalInfoUseCase.validateWeight(sanitizedWeight) {
            case .success(let weight):
                return .from([
                    .setWeightText(sanitizedWeight),
                    .setWeight(weight)
                ])
            case .failure(let error):
                return .from([
                    .setWeightText(sanitizedWeight),
                    .setWeight(nil),
                    .setError(error.title, error.message)
                ])
            }

        case .save:
            return saveProfile()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setProfile(let profile):
            newState.originalProfile = profile
            newState.nickname = profile.nickname
            newState.birthdayText = birthdayFormatter.string(from: profile.birthDate)
            newState.birthDate = profile.birthDate
            newState.gender = profile.gender
            newState.height = profile.height
            newState.heightText = Self.displayText(from: profile.height)
            newState.weight = profile.initialWeight
            newState.weightText = Self.displayText(from: profile.initialWeight)
        case .setNickname(let nickname):
            newState.nickname = nickname
        case .setBirthdayText(let birthdayText):
            newState.birthdayText = birthdayText
        case .setBirthDate(let birthDate):
            newState.birthDate = birthDate
        case .setGender(let gender):
            newState.gender = gender
        case .setHeightText(let heightText):
            newState.heightText = heightText
        case .setHeight(let height):
            newState.height = height
        case .setWeightText(let weightText):
            newState.weightText = weightText
        case .setWeight(let weight):
            newState.weight = weight
        case .setIsSaving(let isSaving):
            newState.isSaving = isSaving
        case .setSaveCompleted:
            newState.saveCompleted = true
        case .setError(let title, let message):
            newState.error = (title, message)
        }

        return newState
    }
}

private extension ProfileManagementReactor {
    func saveProfile() -> Observable<Mutation> {
        guard currentState.isSaveButtonEnabled,
              let originalProfile = currentState.originalProfile,
              let birthDate = currentState.birthDate else {
            return .empty()
        }

        let input = UpsertUserProfileUseCase.Input(
            nickname: currentState.nickname,
            birthDate: birthDate,
            gender: currentState.gender,
            height: currentState.height,
            initialWeight: currentState.weight,
            exerciseExperience: originalProfile.exerciseExperience,
            exerciseGoal: originalProfile.exerciseGoal,
            preferredSportsCategories: originalProfile.preferredSportsCategories,
            discomfortBodyParts: originalProfile.discomfortBodyParts,
            usesPublicFacility: originalProfile.usesPublicFacility
        )

        return .concat([
            .just(.setIsSaving(true)),
            upsertUserProfileUseCase.execute(input)
                .asObservable()
                .flatMap { profile -> Observable<Mutation> in
                    .from([
                        .setProfile(profile),
                        .setSaveCompleted
                    ])
                }
                .catch { _ in .just(.setError("저장 실패", "프로필 정보를 저장하지 못했어요.")) },
            .just(.setIsSaving(false))
        ])
    }

    static func displayText(from value: Double?) -> String {
        guard let value else { return "" }

        if value.rounded() == value {
            return "\(Int(value))"
        }

        return "\(value)"
    }
}
