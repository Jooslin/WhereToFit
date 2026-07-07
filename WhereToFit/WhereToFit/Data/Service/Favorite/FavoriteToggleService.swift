//
//  FavoriteToggleService.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation
import RxSwift

final class FavoriteToggleService {
    private let addFacilityFavoriteUseCase: AddFacilityFavoriteUseCase
    private let addProgramFavoriteUseCase: AddProgramFavoriteUseCase
    private let removeFavoriteUseCase: RemoveFavoriteUseCase

    init(repository: FavoriteRepositoryProtocol) {
        self.addFacilityFavoriteUseCase = AddFacilityFavoriteUseCase(repository: repository)
        self.addProgramFavoriteUseCase = AddProgramFavoriteUseCase(repository: repository)
        self.removeFavoriteUseCase = RemoveFavoriteUseCase(repository: repository)
    }

    func setFavorite(
        targetKey: FavoriteTargetKey,
        facility: FitnessFacility,
        isSelected: Bool
    ) -> Observable<Void> {
        guard isSelected else {
            return removeFavoriteUseCase
                .execute(
                    targetType: targetKey.targetType,
                    targetID: targetKey.targetID
                )
                .andThen(Single.just(()))
                .asObservable()
        }

        switch targetKey.targetType {
        case .facility:
            return addFacilityFavoriteUseCase
                .execute(makeFacilityFavoriteInput(targetKey: targetKey, facility: facility))
                .map { _ in () }
                .asObservable()

        case .program:
            return addProgramFavoriteUseCase
                .execute(makeProgramFavoriteInput(targetKey: targetKey, program: facility))
                .map { _ in () }
                .asObservable()
        }
    }
}

private extension FavoriteToggleService {
    func makeFacilityFavoriteInput(
        targetKey: FavoriteTargetKey,
        facility: FitnessFacility
    ) -> AddFacilityFavoriteUseCase.Input {
        AddFacilityFavoriteUseCase.Input(
            targetID: targetKey.targetID,
            name: nonEmptyText(facility.locationName) ?? facility.name,
            sportsCategoryRawValue: facility.category.title,
            day: facility.dayText,
            time: facility.availableTimeRange.title,
            distance: facility.distanceText,
            price: facility.priceText,
            imageURLString: facility.imageURL?.absoluteString
        )
    }

    func makeProgramFavoriteInput(
        targetKey: FavoriteTargetKey,
        program: FitnessFacility
    ) -> AddProgramFavoriteUseCase.Input {
        AddProgramFavoriteUseCase.Input(
            targetID: targetKey.targetID,
            name: program.name,
            programCenterName: nonEmptyText(program.locationName),
            sportsCategoryRawValue: program.category.title,
            day: program.dayText,
            time: program.availableTimeRange.title,
            distance: program.distanceText,
            price: program.priceText,
            reservationMethods: nonEmptyText(program.applicationMethodText),
            imageURLString: program.imageURL?.absoluteString
        )
    }

    func nonEmptyText(_ text: String?) -> String? {
        let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText?.isEmpty == false ? trimmedText : nil
    }
}
