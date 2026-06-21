//
//  FetchNearbyFacilitiesUseCase.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import Foundation
import RxSwift

// MARK: - 가져온 데이터를 사용자가 고른 조건에 맞도록 필터링
final class FetchNearbyFacilitiesUseCase {
    private let repository: FacilityRepositoryProtocol

    init(repository: FacilityRepositoryProtocol) {
        self.repository = repository
    }

    func fetch() -> Single<FitnessFacilityDataSet> {
        repository.fetchFacilities()
    }
    
    func searchFacilities(keyword: String) -> Single<[FitnessFacility]> {
        repository.searchFacilities(keyword: keyword)
    }

    func fetchPrograms(for facilities: [FitnessFacility]) -> Single<[FitnessFacility]> {
        repository.fetchPrograms(for: facilities)
    }

    func filter(
        facilities: [FitnessFacility],
        searchText: String,
        filter: FacilityFilter
    ) -> [FitnessFacility] {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filtered = facilities.filter { facility in
            // 검색어가 시설명, 주소, 카테고리명에 포함되는지 확인
            let matchesSearch = normalizedSearchText.isEmpty
                || facility.name.lowercased().contains(normalizedSearchText)
                || facility.address.lowercased().contains(normalizedSearchText)
                || facility.category.title.lowercased().contains(normalizedSearchText)

            let matchesCategory = filter.categories.isEmpty || filter.categories.contains(facility.category)
            
            let matchesKnownPriceRange = (filter.minimumPrice.map { facility.price >= $0 } ?? true)
                && (filter.maximumPrice.map { facility.price <= $0 } ?? true)
            // 가격을 숫자로 판단할 수 없는 항목은 가격 필터와 관계없이 노출합니다.
            let matchesPrice = shouldIgnorePriceFilter(for: facility) || matchesKnownPriceRange
            // 선택한 시간대, 요일에 포함되는지 확인
            let matchesDay = filter.days.isEmpty
                || Set(facility.availableDays).isDisjoint(with: filter.days) == false
            let matchesTime = filter.timeSlots.isEmpty
                || filter.timeSlots.contains { facility.availableTimeRange.overlaps($0.range) }

            return matchesSearch && matchesCategory && matchesPrice && matchesDay && matchesTime
        }

        // AI 추천이 켜져있으면 높은 매칭률 순으로 정렬
        if filter.isAIRecommendationEnabled {
            return filtered.sorted {
                if $0.matchingRate == $1.matchingRate {
                    // 거리가 가까운 순으로 정렬
                    return $0.distanceInMeters < $1.distanceInMeters
                }
                return $0.matchingRate > $1.matchingRate
            }
        }

        return filtered.sorted { $0.distanceInMeters < $1.distanceInMeters }
    }

    private func shouldIgnorePriceFilter(for facility: FitnessFacility) -> Bool {
        facility.priceText == "상세 정보 확인"
    }
}
