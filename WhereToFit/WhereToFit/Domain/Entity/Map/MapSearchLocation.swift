//
//  MapSearchLocation.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation

/// 네이버 검색 결과를 앱 내부에서 쓰기 좋은 형태로 정리한 위치 모델입니다.
/// 외부 API 응답 필드가 바뀌어도 UseCase는 이 모델만 바라보도록 합니다.
nonisolated struct MapSearchLocation: Equatable, Sendable {
    let title: String // 검색 결과 대표 이름
    let subtitle: String // 보조 설명
    let coordinate: GeoCoordinate // 위,경도
}
