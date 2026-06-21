//
//  NaverMapSearchRepository.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import Foundation
import RxSwift

/// 네이버 Geocode API와 Local Search API를 묶어 지도 검색용 위치 결과를 제공합니다.
/// UseCase가 외부 API 응답 구조를 몰라도 되도록 여기서 앱 내부 모델로 변환합니다.
final class NaverMapSearchRepository: MapSearchRepositoryProtocol, AddressCoordinateRepositoryProtocol {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func searchLocations(query: String) async throws -> [MapSearchLocation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        // 주소형 검색과 장소명 검색은 서로 보완적이라 둘 다 호출한 뒤 합칩니다.
        async let geocodeFetch = fetchLocations {
            try await networkService.fetchNaverGeocodeLocations(query: trimmedQuery)
        }
        async let localSearchFetch = fetchLocations {
            try await networkService.fetchNaverLocalSearchLocations(query: trimmedQuery)
        }

        let geocodeResult = await geocodeFetch
        let localSearchResult = await localSearchFetch

        let locations = mergeLocations(
            geocodeResult.value ?? [],
            localSearchResult.value ?? []
        )

        // 둘 중 하나라도 결과를 가져오면 성공으로 보고, 둘 다 실패/빈 값일 때만 오류를 전달합니다.
        if locations.isEmpty,
           let error = geocodeResult.failure ?? localSearchResult.failure {
            throw error
        }

        return locations
    }

    func coordinate(for address: String) -> Single<GeoCoordinate?> {
        Single.create { [networkService] single in
            let task = Task {
                do {
                    let coordinate = try await networkService.fetchNaverGeocode(query: address)
                    guard Task.isCancelled == false else { return }
                    single(.success(coordinate))
                } catch {
                    guard Task.isCancelled == false else { return }
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func fetchLocations(
        _ operation: () async throws -> [NaverGeocodeLocation]
    ) async -> Result<[NaverGeocodeLocation], Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    private func mergeLocations(_ locationGroups: [NaverGeocodeLocation]...) -> [MapSearchLocation] {
        var seenKeys = Set<String>()
        var locations: [MapSearchLocation] = []

        // 같은 장소가 두 API에서 중복으로 내려올 수 있어 제목/주소/좌표 조합으로 제거합니다.
        locationGroups.flatMap { $0 }.forEach { location in
            let key = [
                location.title.normalizedMapSearchKey,
                location.subtitle.normalizedMapSearchKey,
                "\(location.coordinate.latitude)",
                "\(location.coordinate.longitude)"
            ].joined(separator: "|")

            guard seenKeys.insert(key).inserted else { return }
            locations.append(
                MapSearchLocation(
                    title: location.title,
                    subtitle: location.subtitle,
                    coordinate: location.coordinate
                )
            )
        }

        return locations
    }
}

private extension Result {
    var value: Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    var failure: Failure? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

private extension String {
    var normalizedMapSearchKey: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
