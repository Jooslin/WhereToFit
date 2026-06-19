//
//  UpdateUserLocationUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

/*
 주소 수정 화면에서 기존 주소를 변경하면
 -> ViewController가 Reactor에 Action 전달
 -> Reactor가 UpdateUserLocationUseCase.Input 생성
 -> updateUserLocationUseCase.execute(input) 호출
 -> Repository가 같은 id를 가진 주소를 찾아 CoreData에 업데이트하는 식으로 이루어집니다.
*/

final class UpdateUserLocationUseCase {
    // 기존 주소 수정에 필요한 입력값을 UseCase로 넘기기 위한 형태
    // 기존 id와 createdAt은 유지하고, 수정 시점에 updatedAt만 새로 갱신합니다.
    struct Input {
        let id: UUID
        let userProfileID: UUID
        let name: String?
        let address: String
        let latitude: Double
        let longitude: Double
        let isSelected: Bool
        let kind: UserLocationKind
        let createdAt: Date
    }

    // UseCase는 저장 방식(CoreData 등)을 직접 알지 않고 Repository Protocol에만 의존
    private let repository: UserLocationRepositoryProtocol

    init(repository: UserLocationRepositoryProtocol) {
        self.repository = repository
    }

    // 입력값을 앱 저장 규칙에 맞게 UserLocation으로 변환한 뒤 Repository에 저장합니다.
    func execute(_ input: Input) -> Single<UserLocation> {
        let now = Date()
        // 사용자가 공백만 입력했거나 앞뒤 공백이 있는 경우를 대비해 저장 전에 정리합니다.
        let trimmedName = input.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = input.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = UserLocation(
            // 주소 수정이므로 기존 id를 유지해야 새 주소가 아니라 기존 주소 업데이트로 처리됩니다.
            id: input.id,
            userProfileID: input.userProfileID,
            // 별도 이름이 없으면 주소 자체를 표시 이름으로 사용합니다.
            name: trimmedName?.isEmpty == false ? trimmedName ?? trimmedAddress : trimmedAddress,
            address: trimmedAddress,
            latitude: input.latitude,
            longitude: input.longitude,
            isSelected: input.isSelected,
            kind: input.kind,
            createdAt: input.createdAt,
            updatedAt: now
        )

        return repository.saveUserLocation(location)
    }
}
