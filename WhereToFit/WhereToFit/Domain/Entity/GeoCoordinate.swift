//
//  GeoCoordinate.swift
//  WhereToFit
//
//  Created by 변예린 on 7/21/26.
//
import Foundation

nonisolated struct GeoCoordinate: Equatable, Sendable {
    let latitude: Double // 위도
    let longitude: Double // 경도
}

// 검색용 위치 범위
nonisolated struct CoordinateBounds {
    let latitude: ClosedRange<Double>
    let longitude: ClosedRange<Double>
}

extension GeoCoordinate {
    func distance(to destination: GeoCoordinate) -> Double {
        return 0
    }
    
    func bounds(radiusMeters: Double) -> CoordinateBounds {
        let latitudeDelta = radiusMeters / 111_000.0
        let longitudeDelta = radiusMeters / (111_000.0 * cos(latitude * .pi / 180))
        
        return CoordinateBounds(
            latitude: (latitude - latitudeDelta)...(latitude + latitudeDelta),
            longitude: (longitude - longitudeDelta)...(longitude + longitudeDelta)
        )
    }
}
