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
    func distance(to destination: GeoCoordinate?) -> Double {
        guard let destination else {
            return Double.greatestFiniteMagnitude
        }
        
        let earthRadius = 6_371_000.0
        
        let startLatitude = latitude * .pi / 180
        let endLatitude = latitude * .pi / 180
        
        let latitudeDelta = (destination.latitude - latitude) * .pi / 180
        let longitudeDelta = (destination.longitude - longitude) * .pi / 180
        
        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
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
