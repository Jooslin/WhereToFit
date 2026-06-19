//
//  AddFacilityFavoriteUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

/*
 사용 설명:
 시설 찜 버튼을 눌렀을 때 사용합니다.
아래처럼 해당 시설의 정보를 Input으로 바꿔 호출합니다.(단순 예시입니다.)

 let input = AddFacilityFavoriteUseCase.Input(
     targetID: facility.id,
     name: facility.name,
     sportsCategoryRawValue: facility.category.title,
     day: facility.dayText,
     time: facility.availableTimeRange.title,
     distance: facility.distanceText,
     price: facility.priceText
 )
 addFacilityFavoriteUseCase.execute(input)

 구현 설명:
 이 UseCase는 시설 찜으로 구분되도록 targetType을 .facility로 고정하고,
 찜 목록 화면에서 바로 그릴 수 있도록 표시값을 FavoriteSnapshot JSON으로 변환해 함께 저장합니다.
 실제 저장 방식(CoreData, CloudKit 동기화 등)은 Repository 구현체에 위임합니다.
*/

final class AddFacilityFavoriteUseCase {
    struct Input {
        let targetID: String // 해당 시설 아이디
        let name: String // 시설 이름
        let sportsCategoryRawValue: String? // 운동 종목명
        let day: String // 운영 날짜
        let time: String // 시간
        let distance: String // 거리
        let price: String // 가격
    }

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ input: Input) -> Single<Favorite> {
        let now = Date()
        let favorite = Favorite(
            id: UUID(),
            targetType: .facility,
            targetID: input.targetID,
            name: input.name,
            programCenterName: nil,
            sportsCategoryRawValue: input.sportsCategoryRawValue,
            snapshotJSON: makeSnapshotJSON(input),
            createdAt: now,
            updatedAt: now
        )

        return repository.saveFavorite(favorite)
    }
}

private extension AddFacilityFavoriteUseCase {
    struct FavoriteSnapshot: Encodable {
        let day: String
        let time: String
        let distance: String
        let price: String
        let facilityLabelText: String?
    }

    func makeSnapshotJSON(_ input: Input) -> String? {
        let snapshot = FavoriteSnapshot(
            day: input.day,
            time: input.time,
            distance: input.distance,
            price: input.price,
            facilityLabelText: nil
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
