//
//  FacilityRepositoryProtocol.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import Foundation
import RxSwift

protocol FacilityRepositoryProtocol {
    func fetchFacilities() -> Single<FitnessFacilityDataSet>
    func fetchPrograms(for facilities: [FitnessFacility]) -> Single<[FitnessFacility]>
}
