//
//  SportsRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import RxSwift

/**
 운동 관련(시설, 프로그램 등) Repository에 적용하는 프로토콜입니다.  구현체에서 채택하여 사용합니다.
 
 구현체는 아래와 같이 사용할 수 있습니다.
 ```swift
 private lazy var sportsRepository = SportsRepository(networkService: networkService) // 실제 사용 시 의존성 주입 Flow에서 진행

 let publicFacility = sportsRepository.fetchFacilities(limit: 5) // 5개의 시설이 담긴 1개의 페이지를 가져옵니다. (id 오름차순 순서)
 let filteredClassInformationPage = sportsRepository.searchPrograms(keyword: "탁구") // "탁구" 키워드로 찾은 프로그램들을 가져옵니다.
 
 // Reactor mutate에서 아래처럼 사용할 수 있습니다.
 return sportsRepository.searchPrograms(keyword: "탁구")
     .asObservable()
     .map { Mutation.setPrograms($0.items) }
 ```

대상 정보가 많을 수도 있으므로 페이지네이션을 하여 데이터를 끊어서 가져옵니다.
 
 만약 컬렉션뷰에서 전체 시설을 조회할 경우, 처음에는 첫 번째 페이지의 정보만 가져온 후 스크롤이 끝나는 지점에서 다음 페이지를 호출하여 가져오는 방식으로 무한 스크롤을 구현할 수 있습니다.
 
 무한 스크롤은 `nextOffset`을 저장해두고, 마지막 셀 근처에서 다음 페이지를 요청하는 방식으로 구현할 수 있습니다.
 ```swift
 private var facilities: [Facility] = []
 private var nextOffset: Int?
 private let pageSize = 20
 
 func loadNextPageIfNeeded(currentIndex: Int) -> Single<SupabasePage<Facility>>? {
     guard currentIndex >= facilities.count - 3, // 현재 화면에 보이는 셀이 끝에서 3번째 즈음일 때 다음 페이지 불러옴
           let nextOffset else {
         return nil
     }
 
     return sportsRepository.fetchFacilities( // 다음 페이지 가져옴
         limit: pageSize,
         offset: nextOffset
     )
 }
 ```
 
 한번에 불러오는 데이터의 수를 줄임으로써 불필요한 로딩 대기 시간을 감소할 수 있습니다.
*/
protocol SportsRepositoryProtocol {
    func fetchFacilities(
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) -> Single<SupabasePage<Facility>>

    func fetchFacilities(
        limit: Int,
        offset: Int,
        order: SearchOrder,
        includesTotalCount: Bool
    ) -> Single<SupabasePage<Facility>>
    
    func searchFacilities(
        keyword: String,
        limit: Int,
        offset: Int,
        order: SearchOrder,
        searchType: NetworkService.SearchType
    ) -> Single<SupabasePage<Facility>>
    
    func fetchPrograms(
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) -> Single<SupabasePage<Program>>

    func fetchPrograms(
        facilityIDs: [String],
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) -> Single<SupabasePage<Program>>
    
    func searchPrograms(
        keyword: String,
        limit: Int,
        offset: Int,
        order: SearchOrder
    ) -> Single<SupabasePage<Program>>
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
        Single.async { [networkService] in
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
