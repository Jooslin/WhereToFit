//
//  AddUserLocationUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

/*
 주소 추가 화면에서 주소를 선택하거나 입력하면
 -> ViewController가 Reactor에 Action 전달
 -> Reactor가 AddUserLocationUseCase.Input 생성
 -> addUserLocationUseCase.execute(input) 호출
 -> Repository가 CoreData에 저장하는 식으로 이루어집니다.
*/

final class AddUserLocationUseCase {
    // 새 주소 추가에 필요한 입력값을 UseCase로 넘기기 위한 형태
    // 화면에서 받은 값은 그대로 전달하고, 저장 전에 필요한 정리는 execute 메서드에서 처리합니다.
    struct Input {
        let userProfileID: UUID
        let name: String?
        let address: String
        let latitude: Double
        let longitude: Double
        let isSelected: Bool
        let kind: UserLocationKind
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
            // 주소 추가이므로 항상 새 id를 발급합니다.
            id: UUID(),
            userProfileID: input.userProfileID,
            // 별도 이름이 없으면 주소 자체를 표시 이름으로 사용합니다.
            name: trimmedName?.isEmpty == false ? trimmedName ?? trimmedAddress : trimmedAddress,
            address: trimmedAddress,
            latitude: input.latitude,
            longitude: input.longitude,
            isSelected: input.isSelected,
            kind: input.kind,
            createdAt: now,
            updatedAt: now
        )

        return repository.saveUserLocation(location)
    }
}
