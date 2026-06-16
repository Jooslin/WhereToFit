//
//  SearchMapSuggestionsUseCase.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation

/// 지도 검색 추천을 만드는 UseCase입니다.
/// 로컬 시설 검색과 네이버 장소 검색을 같은 `MapSearchSuggestion`으로 변환해 Presentation에서 단순히 렌더링만 하게 합니다.
final class SearchMapSuggestionsUseCase {
    struct Configuration {
        let minimumRemoteQueryLength: Int // 검색어가 2자 이상일때만 네이버 검색 호출
        let localSuggestionLimit: Int
        let mergedSuggestionLimit: Int
        let localPreferredZoom: Double
        let remotePreferredZoom: Double
        let multipleLocalResultPreferredZoom: Double

        static let `default` = Configuration(
            minimumRemoteQueryLength: 2,
            localSuggestionLimit: 5,
            mergedSuggestionLimit: 6,
            localPreferredZoom: 15,
            remotePreferredZoom: 14,
            multipleLocalResultPreferredZoom: 13
        )
    }

    private let repository: MapSearchRepositoryProtocol
    private let configuration: Configuration

    init(
        repository: MapSearchRepositoryProtocol,
        configuration: Configuration = .default
    ) {
        self.repository = repository
        self.configuration = configuration
    }

    func makeLocalSuggestions(
        query: String,
        facilities: [FitnessFacility],
        referenceCoordinate: GeoCoordinate
    ) -> [MapSearchSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        // 로컬 시설은 현재 위치 기준 가까운 순서로 먼저 보여줍니다.
        return facilities
            .filter { $0.matchesMapSearchQuery(trimmedQuery) }
            .map { facility in
                (
                    facility: facility,
                    distanceInMeters: Self.distanceInMeters(
                        from: referenceCoordinate,
                        to: facility.coordinate
                    )
                )
            }
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
            .prefix(configuration.localSuggestionLimit)
            .map { item in
                MapSearchSuggestion(
                    title: item.facility.searchSuggestionTitle,
                    subtitle: item.facility.address,
                    distanceText: Self.formatDistanceText(item.distanceInMeters),
                    coordinate: item.facility.coordinate,
                    facilityID: item.facility.id,
                    preferredZoom: configuration.localPreferredZoom
                )
            }
    }

    func fetchRemoteSuggestions(
        query: String,
        referenceCoordinate: GeoCoordinate
    ) async -> [MapSearchSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= configuration.minimumRemoteQueryLength else {
            return []
        }

        // 네이버 검색 실패가 지도 화면 전체 실패로 번지지 않도록 추천 목록만 비워둡니다.
        let locations = (try? await repository.searchLocations(query: trimmedQuery)) ?? []
        return locations.map { location in
            MapSearchSuggestion(
                title: location.title,
                subtitle: location.subtitle,
                distanceText: Self.distanceText(
                    from: referenceCoordinate,
                    to: location.coordinate
                ),
                coordinate: location.coordinate,
                facilityID: nil,
                preferredZoom: configuration.remotePreferredZoom
            )
        }
    }

    func mergeSuggestions(
        _ localSuggestions: [MapSearchSuggestion],
        _ remoteSuggestions: [MapSearchSuggestion]
    ) -> [MapSearchSuggestion] {
        var seenKeys = Set<String>()
        var mergedSuggestions: [MapSearchSuggestion] = []

        // 로컬 시설을 먼저 유지하고, 같은 제목/주소의 네이버 결과는 중복 제거합니다.
        (localSuggestions + remoteSuggestions).forEach { suggestion in
            let key = "\(suggestion.title.normalizedMapSearchText)-\(suggestion.subtitle.normalizedMapSearchText)"
            guard seenKeys.contains(key) == false else { return }
            seenKeys.insert(key)
            mergedSuggestions.append(suggestion)
        }

        return Array(mergedSuggestions.prefix(configuration.mergedSuggestionLimit))
    }

    func makeLocalSearchResult(
        query: String,
        facilities: [FitnessFacility],
        fallbackCoordinate: GeoCoordinate
    ) -> MapSearchResult? {
        let matchedFacilities = facilities
            .filter { $0.matchesMapSearchQuery(query) }
            .sorted { $0.distanceInMeters < $1.distanceInMeters }

        guard matchedFacilities.isEmpty == false else {
            return nil
        }

        // 여러 시설이 동시에 매칭되면 평균 좌표로 이동해 주변 결과를 한 번에 볼 수 있게 합니다.
        return MapSearchResult(
            coordinate: Self.centerCoordinate(
                of: matchedFacilities,
                fallbackCoordinate: fallbackCoordinate
            ),
            selectedFacilityID: matchedFacilities.count == 1 ? matchedFacilities[0].id : nil,
            preferredZoom: matchedFacilities.count == 1
                ? configuration.localPreferredZoom
                : configuration.multipleLocalResultPreferredZoom
        )
    }

    private static func centerCoordinate(
        of facilities: [FitnessFacility],
        fallbackCoordinate: GeoCoordinate
    ) -> GeoCoordinate {
        guard facilities.isEmpty == false else {
            return fallbackCoordinate
        }

        let latitude = facilities.map(\.coordinate.latitude).reduce(0, +) / Double(facilities.count)
        let longitude = facilities.map(\.coordinate.longitude).reduce(0, +) / Double(facilities.count)
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }

    private static func distanceText(from source: GeoCoordinate, to destination: GeoCoordinate) -> String {
        formatDistanceText(distanceInMeters(from: source, to: destination))
    }

    private static func distanceInMeters(from source: GeoCoordinate, to destination: GeoCoordinate) -> Int {
        let earthRadiusInMeters = 6_371_000.0
        let sourceLatitude = source.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let latitudeDelta = (destination.latitude - source.latitude) * .pi / 180
        let longitudeDelta = (destination.longitude - source.longitude) * .pi / 180
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(sourceLatitude) * cos(destinationLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        let angularDistance = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))

        return Int((earthRadiusInMeters * angularDistance).rounded())
    }

    private static func formatDistanceText(_ distanceInMeters: Int) -> String {
        guard distanceInMeters >= 1000 else {
            return "\(distanceInMeters)m"
        }

        let distanceInKilometers = Double(distanceInMeters) / 1000
        if distanceInKilometers >= 10 {
            return "\(Int(distanceInKilometers.rounded()))km"
        }

        let roundedDistance = (distanceInKilometers * 10).rounded() / 10
        if roundedDistance == roundedDistance.rounded() {
            return "\(Int(roundedDistance))km"
        }

        return String(format: "%.1fkm", roundedDistance)
    }
}

private extension FitnessFacility {
    var searchSuggestionTitle: String {
        if let locationName,
           locationName.isEmpty == false {
            return locationName
        }

        return name
    }

    func matchesMapSearchQuery(_ query: String) -> Bool {
        let normalizedQuery = query.normalizedMapSearchText
        guard normalizedQuery.isEmpty == false else { return false }

        // 시설명, 장소명, 주소, 카테고리명 중 하나라도 포함되면 로컬 검색 결과로 취급합니다.
        return [
            name,
            locationName,
            address,
            category.title
        ]
        .compactMap { $0 }
        .map(\.normalizedMapSearchText)
        .contains { $0.contains(normalizedQuery) }
    }
}

private extension String {
    var normalizedMapSearchText: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
