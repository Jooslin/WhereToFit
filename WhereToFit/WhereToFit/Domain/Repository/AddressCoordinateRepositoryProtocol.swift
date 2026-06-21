//
//  AddressCoordinateRepositoryProtocol.swift
//  WhereToFit
//
//  Created by 변예린 on 6/20/26.
//

import Foundation
import RxSwift

protocol AddressCoordinateRepositoryProtocol {
    func coordinate(for address: String) -> Single<GeoCoordinate?>
}
