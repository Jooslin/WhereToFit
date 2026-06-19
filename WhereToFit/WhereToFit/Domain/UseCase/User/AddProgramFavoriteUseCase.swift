//
//  AddProgramFavoriteUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/19/26.
//

import Foundation
import RxSwift

/*
 프로그램 찜 버튼을 눌렀을 때 사용합니다.
 아래처럼 값을 Input으로 바꿔 호출합니다. (단순 예시입니다.)

 let input = AddProgramFavoriteUseCase.Input(
     targetID: facility.id,
     name: facility.name,
     programCenterName: facility.locationName,
     sportsCategoryRawValue: facility.category.title,
     day: facility.dayText,
     time: facility.availableTimeRange.title,
     distance: facility.distanceText,
     price: facility.priceText,
     reservationMethods: "온라인, 직접방문",
     imageURLString: facility.imageURL?.absoluteString
 )
 addProgramFavoriteUseCase.execute(input)

 이 UseCase는 프로그램 찜으로 구분되도록 targetType을 .program으로 고정하고,
 찜 목록 화면에서 바로 그릴 수 있도록 표시값을 FavoriteSnapshot JSON으로 변환해 함께 저장합니다.
 실제 저장 방식(CoreData, CloudKit 동기화 등)은 Repository 구현체에 위임합니다.
*/

final class AddProgramFavoriteUseCase {
    struct Input {
        let targetID: String // 프로그램 아이디
        let name: String // 프로그램 이름
        let programCenterName: String? // 프로그램 운영 시설 이름
        let sportsCategoryRawValue: String? // 종목 이름
        let day: String // 운영 요일
        let time: String // 운영 시간
        let distance: String // 거리
        let price: String // 가격
        let reservationMethods: String?
        let imageURLString: String?
    }

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ input: Input) -> Single<Favorite> {
        let now = Date()
        let favorite = Favorite(
            id: UUID(),
            targetType: .program,
            targetID: input.targetID,
            name: input.name,
            programCenterName: input.programCenterName,
            sportsCategoryRawValue: input.sportsCategoryRawValue,
            snapshotJSON: makeSnapshotJSON(input),
            createdAt: now,
            updatedAt: now
        )
        return repository.saveFavorite(favorite)
    }
}

private extension AddProgramFavoriteUseCase {
    struct FavoriteSnapshot: Encodable {
        let day: String
        let time: String
        let distance: String
        let price: String
        let facilityLabelText: String?
        let reservationMethods: String?
        let imageURLString: String?
    }

    func makeSnapshotJSON(_ input: Input) -> String? {
        let facilityLabelText = input.programCenterName.map { "\($0) |" }
        let snapshot = FavoriteSnapshot(
            day: input.day,
            time: input.time,
            distance: input.distance,
            price: input.price,
            facilityLabelText: facilityLabelText,
            reservationMethods: input.reservationMethods,
            imageURLString: input.imageURLString
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
