//
//  MapMarkerRenderer.swift
//  WhereToFit
//
//  Created by 김주희 on 6/17/26.
//

import UIKit
import NMapsMap

struct MapFacilityMarkerGroup {
    let coordinate: GeoCoordinate
    var facilities: [FitnessFacility]
}

/// 지도 줌 레벨과 시설 목록을 바탕으로 Naver Map 마커를 렌더링하는 전담 객체입니다.
/// `MapViewController`는 마커 탭 이후의 화면 전환/상태 변경만 처리하고, 마커 생성 방식은 이 타입이 관리합니다.
final class MapMarkerRenderer {
    static let clusterExpansionZoom: Double = MapMarkerZoomLevel.sameCoordinateCountMarkerMinimum

    var didTapFacilityMarker: ((FitnessFacility) -> Void)?
    var didTapFacilityGroupMarker: ((MapFacilityMarkerGroup, Bool) -> Void)?

    private var markers: [NMFMarker] = []
    private var renderedPresentationStyle: MapMarkerPresentationStyle?

    func render(_ facilities: [FitnessFacility], on naverMapView: NMFMapView) {
        let presentationStyle = presentationStyle(for: naverMapView.zoomLevel)
        renderedPresentationStyle = presentationStyle
        markers.forEach { $0.mapView = nil }

        // 가까이서는 개별 gym 마커, 중간 줌에서는 같은 좌표 묶음, 멀리서는 근처 시설 클러스터를 사용합니다.
        switch presentationStyle {
        case .gym:
            markers = makeGymMarkers(from: facilities, on: naverMapView)

        case .sameCoordinateCount:
            markers = makeCountMarkers(
                from: makeSameCoordinateMarkerGroups(from: facilities),
                on: naverMapView
            )

        case let .nearbyCount(clusterGridSizeMeters):
            markers = makeCountMarkers(
                from: makeNearbyMarkerGroups(
                    from: facilities,
                    clusterGridSizeMeters: clusterGridSizeMeters
                ),
                on: naverMapView,
                opensClusterOnTap: true
            )
        }
    }

    func refreshIfNeeded(for facilities: [FitnessFacility], on naverMapView: NMFMapView) {
        let currentStyle = presentationStyle(for: naverMapView.zoomLevel)
        guard renderedPresentationStyle != currentStyle else { return }
        render(facilities, on: naverMapView)
    }

    private func presentationStyle(for zoomLevel: Double) -> MapMarkerPresentationStyle {
        // 줌 레벨 기준은 UI 가독성 기준입니다. 숫자를 바꾸면 마커 전환 시점이 함께 바뀝니다.
        if zoomLevel >= MapMarkerZoomLevel.gymMarkerMinimum {
            return .gym
        }

        if zoomLevel >= MapMarkerZoomLevel.sameCoordinateCountMarkerMinimum {
            return .sameCoordinateCount
        }

        return .nearbyCount(clusterGridSizeMeters: nearbyClusterGridSizeMeters(for: zoomLevel))
    }

    private func makeGymMarkers(from facilities: [FitnessFacility], on naverMapView: NMFMapView) -> [NMFMarker] {
        let markerIconImage = makeGymMarkerImage()
        return facilities.map { facility in
            let marker = NMFMarker(
                position: NMGLatLng(
                    lat: facility.coordinate.latitude,
                    lng: facility.coordinate.longitude
                )
            )
            marker.iconImage = NMFOverlayImage(image: markerIconImage)
            marker.width = markerIconImage.size.width
            marker.height = markerIconImage.size.height
            marker.anchor = CGPoint(x: 0.5, y: 0.5)
            marker.touchHandler = { [weak self] _ in
                self?.didTapFacilityMarker?(facility)
                return true
            }
            marker.mapView = naverMapView
            return marker
        }
    }

    private func makeCountMarkers(
        from markerGroups: [MapFacilityMarkerGroup],
        on naverMapView: NMFMapView,
        opensClusterOnTap: Bool = false
    ) -> [NMFMarker] {
        markerGroups.compactMap { group in
            guard group.facilities.first != nil else { return nil }

            let markerIconImage = makeFacilityCountMarkerImage(for: group.facilities)
            let marker = NMFMarker(
                position: NMGLatLng(
                    lat: group.coordinate.latitude,
                    lng: group.coordinate.longitude
                )
            )
            marker.iconImage = NMFOverlayImage(image: markerIconImage)
            marker.width = markerIconImage.size.width
            marker.height = markerIconImage.size.height
            marker.anchor = CGPoint(x: 0.5, y: 0.5)
            marker.touchHandler = { [weak self] _ in
                self?.didTapFacilityGroupMarker?(group, opensClusterOnTap)
                return true
            }
            marker.mapView = naverMapView
            return marker
        }
    }

    private func makeGymMarkerImage() -> UIImage {
        let size = CGSize(width: 34, height: 34)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let circlePath = UIBezierPath(ovalIn: bounds)
            UIColor.systemBackground.withAlphaComponent(0.8).setFill()
            circlePath.fill()
            UIColor.primary100.setStroke()
            circlePath.lineWidth = 1
            circlePath.stroke()

            guard let icon = UIImage(named: "gym")?.withRenderingMode(.alwaysOriginal) else { return }
            let iconRect = CGRect(x: 9, y: 9, width: 16, height: 16)
            icon.draw(in: iconRect, blendMode: .normal, alpha: 1)
        }
    }

    private func makeSameCoordinateMarkerGroups(from facilities: [FitnessFacility]) -> [MapFacilityMarkerGroup] {
        facilities.reduce(into: []) { groups, facility in
            if let index = groups.firstIndex(where: { $0.coordinate.isSameLocation(as: facility.coordinate) }) {
                groups[index].facilities.append(facility)
            } else {
                groups.append(MapFacilityMarkerGroup(coordinate: facility.coordinate, facilities: [facility]))
            }
        }
    }

    private func makeNearbyMarkerGroups(
        from facilities: [FitnessFacility],
        clusterGridSizeMeters: Int
    ) -> [MapFacilityMarkerGroup] {
        // 지도 라이브러리 클러스터링 대신 미터 단위 격자로 묶어 카테고리별 숫자 마커를 직접 만듭니다.
        let gridSize = Double(clusterGridSizeMeters)
        let groupedFacilities = Dictionary(grouping: facilities) { facility in
            nearbyClusterKey(for: facility.coordinate, gridSizeMeters: gridSize)
        }

        return groupedFacilities.values.map { facilities in
            MapFacilityMarkerGroup(
                coordinate: centerCoordinate(of: facilities),
                facilities: facilities
            )
        }
    }

    private func nearbyClusterKey(for coordinate: GeoCoordinate, gridSizeMeters: Double) -> String {
        let latitudeMeters = coordinate.latitude * 111_320
        let longitudeMeters = coordinate.longitude
            * 111_320
            * cos(coordinate.latitude * .pi / 180)
        let latitudeIndex = Int(floor(latitudeMeters / gridSizeMeters))
        let longitudeIndex = Int(floor(longitudeMeters / gridSizeMeters))
        return "\(latitudeIndex)-\(longitudeIndex)"
    }

    private func nearbyClusterGridSizeMeters(for zoomLevel: Double) -> Int {
        switch zoomLevel {
        case ..<8:
            return 20_000
        case ..<9:
            return 14_000
        case ..<10:
            return 10_000
        case ..<11:
            return 7_000
        case ..<12:
            return 5_000
        case ..<13:
            return 3_000
        default:
            return 1_800
        }
    }

    private func centerCoordinate(of facilities: [FitnessFacility]) -> GeoCoordinate {
        guard facilities.isEmpty == false else {
            return GeoCoordinate(latitude: 0, longitude: 0)
        }

        let latitude = facilities.map(\.coordinate.latitude).reduce(0, +) / Double(facilities.count)
        let longitude = facilities.map(\.coordinate.longitude).reduce(0, +) / Double(facilities.count)
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }

    private func makeFacilityCountMarkerImage(for facilities: [FitnessFacility]) -> UIImage {
        FacilityCountMarkerView(items: makeFacilityCountMarkerItems(for: facilities)).renderedImage()
    }

    private func makeFacilityCountMarkerItems(for facilities: [FitnessFacility]) -> [FacilityCountMarkerView.Item] {
        markerIconCounts(for: facilities).map { iconName, count in
            FacilityCountMarkerView.Item(
                icon: UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal)
                    ?? UIImage(named: "gym")?.withRenderingMode(.alwaysOriginal),
                count: count
            )
        }
    }

    private func markerIconCounts(for facilities: [FitnessFacility]) -> [(iconName: String, count: Int)] {
        let countsByIconName = facilities.reduce(into: [String: Int]()) { counts, facility in
            counts[facility.category.markerIconName, default: 0] += 1
        }
        var seenIconNames = Set<String>()

        // FacilityCategory 순서를 유지해 마커 안의 아이콘 표시 순서가 매번 흔들리지 않게 합니다.
        return FacilityCategory.allCases.compactMap { category in
            let iconName = category.markerIconName
            guard seenIconNames.insert(iconName).inserted,
                  let count = countsByIconName[iconName] else { return nil }
            return (iconName: iconName, count: count)
        }
    }
}

private enum MapMarkerPresentationStyle: Equatable {
    case gym
    case sameCoordinateCount
    case nearbyCount(clusterGridSizeMeters: Int)
}

private enum MapMarkerZoomLevel {
    static let gymMarkerMinimum: Double = 15
    static let sameCoordinateCountMarkerMinimum: Double = 14
}

extension GeoCoordinate {
    func isSameLocation(as other: GeoCoordinate) -> Bool {
        abs(latitude - other.latitude) < 0.000001
            && abs(longitude - other.longitude) < 0.000001
    }
}
