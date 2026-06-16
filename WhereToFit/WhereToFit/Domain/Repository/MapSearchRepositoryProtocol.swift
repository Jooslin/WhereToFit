//
//  MapSearchRepositoryProtocol.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation

protocol MapSearchRepositoryProtocol {
    /// 검색어에 맞는 외부 위치 결과를 앱 공통 위치 모델로 반환합니다.
    func searchLocations(query: String) async throws -> [MapSearchLocation]
}
