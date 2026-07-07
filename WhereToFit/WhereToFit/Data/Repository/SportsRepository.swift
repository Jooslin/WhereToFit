//
//  SportsRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 7/7/26.
//

import RxSwift

final class SportsRepository: SportsRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchFacilities(
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Facility>> {
        fetchFacilities(
            limit: limit,
            offset: offset,
            order: order,
            includesTotalCount: false
        )
    }

    func fetchFacilities(
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending,
        includesTotalCount: Bool
    ) -> Single<SupabasePage<Facility>> {
        Single.async { [networkService] in
            let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchSupabaseData(
                api: .facility,
                limit: limit,
                offset: offset,
                order: order,
                includesTotalCount: includesTotalCount
            )
            
            return page.map(Facility.init)
        }
    }

    func fetchFacilities(
        facilityIDs: [String],
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Facility>> {
        Single.async { [networkService] in
            guard facilityIDs.isEmpty == false else {
                return SupabasePage(items: [], nextOffset: nil)
            }

            let filterValue = "in.(\(facilityIDs.joined(separator: ",")))"
            let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchSupabaseData(
                api: .facility,
                filters: [
                    "id": filterValue
                ],
                limit: limit,
                offset: offset,
                order: order
            )

            return page.map(Facility.init)
        }
    }
    
    func fetchFacilities(
        latitudeRange: ClosedRange<Double>,
        longitudeRange: ClosedRange<Double>,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Facility>> {
        Single.async { [networkService] in
            let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchSupabaseData(
                api: .facility,
                filters: [
                    "and": "(latitude.gte.\(latitudeRange.lowerBound),latitude.lte.\(latitudeRange.upperBound),longitude.gte.\(longitudeRange.lowerBound),longitude.lte.\(longitudeRange.upperBound))"
                ],
                limit: limit,
                offset: offset,
                order: order
            )
            
            return page.map(Facility.init)
        }
    }
    
    func searchFacilities(
        keyword: String,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending,
        searchType: NetworkService.SearchType = .facilityName
    ) -> Single<SupabasePage<Facility>> {
        Single.async { [networkService] in
            let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchFilteredSupabaseData(
                api: .facility,
                keyword: keyword,
                searchType: searchType,
                order: order,
                limit: limit,
                offset: offset
            )
            
            return page.map(Facility.init)
        }
    }
    
    func fetchPrograms(
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Program>> {
        Single.async { [networkService] in
            let page: SupabasePage<ClassInformationDTO> = try await networkService.fetchSupabaseData(
                api: .classInfo,
                limit: limit,
                offset: offset,
                order: order
            )
            
            return page.map(Program.init)
        }
    }

    func fetchPrograms(
        facilityIDs: [String],
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Program>> {
        Single.async { [networkService] in
            guard facilityIDs.isEmpty == false else {
                return SupabasePage(items: [], nextOffset: nil)
            }

            let filterValue = "in.(\(facilityIDs.joined(separator: ",")))"
            let page: SupabasePage<ClassInformationDTO> = try await networkService.fetchSupabaseData(
                api: .classInfo,
                filters: [
                    "public_facility_id": filterValue
                ],
                limit: limit,
                offset: offset,
                order: order
            )

            return page.map(Program.init)
        }
    }
    
    func searchPrograms(
        keyword: String,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) -> Single<SupabasePage<Program>> {
        searchPrograms(
            keyword: keyword,
            limit: limit,
            offset: offset,
            order: order,
            searchType: .className
        )
    }
    
    func searchPrograms(
        keyword: String,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending,
        searchType: NetworkService.SearchType
    ) -> Single<SupabasePage<Program>> {
        Single.async { [networkService] in
            let page: SupabasePage<ClassInformationDTO> = try await networkService.fetchFilteredSupabaseData(
                api: .classInfo,
                keyword: keyword,
                searchType: searchType,
                order: order,
                limit: limit,
                offset: offset
            )
            
            return page.map(Program.init)
        }
    }
}

private extension SupabasePage {
    func map<MappedItem>(_ transform: (T) -> MappedItem) -> SupabasePage<MappedItem> {
        SupabasePage<MappedItem>(
            items: items.map(transform),
            nextOffset: nextOffset,
            totalCount: totalCount
        )
    }
}
