//
//  SportsRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

protocol SportsRepositoryProtocol {
    func fetchFacilities(
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) async throws -> SupabasePage<Facility>
    
    func searchFacilities(
        keyword: String,
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) async throws -> SupabasePage<Facility>
    
    func fetchPrograms(
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) async throws -> SupabasePage<Program>
    
    func searchPrograms(
        keyword: String,
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) async throws -> SupabasePage<Program>
}

final class SportsRepository: SportsRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchFacilities(
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) async throws -> SupabasePage<Facility> {
        let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchSupabaseData(
            api: .facility,
            limit: limit,
            offset: offset,
            order: order
        )
        
        return page.map(Facility.init)
    }
    
    func searchFacilities(
        keyword: String,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) async throws -> SupabasePage<Facility> {
        let page: SupabasePage<PublicFacilityDTO> = try await networkService.fetchFilteredSupabaseData(
            api: .facility,
            keyword: keyword,
            searchType: .facilityName,
            order: order,
            limit: limit,
            offset: offset
        )
        
        return page.map(Facility.init)
    }
    
    func fetchPrograms(
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) async throws -> SupabasePage<Program> {
        let page: SupabasePage<ClassInformationDTO> = try await networkService.fetchSupabaseData(
            api: .classInfo,
            limit: limit,
            offset: offset,
            order: order
        )
        
        return page.map(Program.init)
    }
    
    func searchPrograms(
        keyword: String,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) async throws -> SupabasePage<Program> {
        let page: SupabasePage<ClassInformationDTO> = try await networkService.fetchFilteredSupabaseData(
            api: .classInfo,
            keyword: keyword,
            searchType: .className,
            order: order,
            limit: limit,
            offset: offset
        )
        
        return page.map(Program.init)
    }
}

private extension SupabasePage {
    func map<MappedItem>(_ transform: (T) -> MappedItem) -> SupabasePage<MappedItem> {
        SupabasePage<MappedItem>(
            items: items.map(transform),
            nextOffset: nextOffset
        )
    }
}
