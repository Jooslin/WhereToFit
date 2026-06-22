//
//  FetchFacilityProgramsUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class FetchFacilityProgramsUseCase {
    private let repository: SportsRepositoryProtocol

    init(repository: SportsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(facilityID: String?, sportName: String?) -> Single<[Program]> {
        guard let facilityID,
              let sportName,
              sportName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return .just([])
        }

        let normalizedSportName = Self.normalize(sportName)

        return repository.fetchPrograms(
            facilityIDs: [facilityID],
            limit: 100,
            offset: 0,
            order: .ascending
        )
        .map { page in
            var seenNames = Set<String>()

            return page.items.filter { program in
                Self.normalize(program.sport) == normalizedSportName
            }
            .filter { program in
                guard let className = program.className?.trimmingCharacters(in: .whitespacesAndNewlines),
                      className.isEmpty == false else {
                    return false
                }

                return seenNames.insert(className).inserted
            }
        }
    }

    private static func normalize(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased() ?? ""
    }
}
