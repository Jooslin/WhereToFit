//
//  MapSearchSuggestion.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation

/// 검색창 아래 추천 목록에 표시할 항목입니다.
/// 로컬 시설 검색 결과와 네이버 검색 결과를 같은 UI로 보여주기 위해 공통 모델로 둡니다.
nonisolated struct MapSearchSuggestion: Equatable, Sendable {
    let title: String // 예: 고양국민체육센터
    let subtitle: String // 예: 경기도 고양시...
    let distanceText: String // 현 위치로부터 거리
    let coordinate: GeoCoordinate // 위,경도
    let facilityID: String? // 시설 ID
    let preferredZoom: Double // 지도를 얼마나 확대할지
}

/// 사용자가 검색을 확정했을 때 지도 이동에 필요한 최소 정보입니다.
nonisolated struct MapSearchResult: Equatable, Sendable {
    let coordinate: GeoCoordinate
    let selectedFacilityID: String?
    let preferredZoom: Double
}
