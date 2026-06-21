//
//  UpsertUserProfileUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

/*
 온보딩 또는 프로필 수정 화면에서 유저 정보를 저장하면
 -> ViewController가 Reactor에 Action 전달
 -> Reactor가 UpsertUserProfileUseCase.Input 생성
 -> upsertUserProfileUseCase.execute(input) 호출
 -> 기존 프로필이 있으면 같은 id로 업데이트하고, 없으면 최초 프로필을 생성합니다.
*/

final class UpsertUserProfileUseCase {
    // 유저 프로필 저장에 필요한 입력값을 UseCase로 넘기기 위한 형태
    // UserProfile.id는 UseCase가 기존 프로필 여부에 따라 결정합니다.
    struct Input {
        let nickname: String
        let birthDate: Date
        let gender: UserGender
        let height: Double?
        let initialWeight: Double?
        let exerciseExperience: ExerciseExperience?
        let exerciseGoal: ExerciseGoal?
        let preferredSportsCategories: [SportsCategory]
        let discomfortBodyParts: [DiscomfortBodyPart]
        let usesPublicFacility: Bool
    }

    // UseCase는 저장 방식(CoreData 등)을 직접 알지 않고 Repository Protocol에만 의존
    private let repository: UserProfileRepositoryProtocol

    init(repository: UserProfileRepositoryProtocol) {
        self.repository = repository
    }
    
    /*
    repository.fetchUserProfile()
    -> 기존 프로필 없음: 새 UUID로 최초 프로필 생성
    -> 기존 프로필 있음: 기존 id, createdAt 유지
    -> updatedAt만 현재 시각으로 갱신
    -> repository.saveUserProfile(profile)
     
    앱은 단일 유저 프로필만 지원합니다.
    기존 프로필이 있으면 id와 createdAt을 유지하고, 없을 때만 새 id를 발급합니다.
     */
    func execute(_ input: Input) -> Single<UserProfile> {
        let now = Date()

        return repository.fetchUserProfile()
            .flatMap { [repository] existingProfile in
                let profile = UserProfile(
                    id: existingProfile?.id ?? UUID(),
                    nickname: input.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    birthDate: input.birthDate,
                    gender: input.gender,
                    height: input.height,
                    initialWeight: input.initialWeight,
                    exerciseExperience: input.exerciseExperience,
                    exerciseGoal: input.exerciseGoal,
                    preferredSportsCategories: input.preferredSportsCategories,
                    discomfortBodyParts: input.discomfortBodyParts,
                    usesPublicFacility: input.usesPublicFacility,
                    createdAt: existingProfile?.createdAt ?? now,
                    updatedAt: now
                )

                return repository.saveUserProfile(profile)
            }
    }
}
