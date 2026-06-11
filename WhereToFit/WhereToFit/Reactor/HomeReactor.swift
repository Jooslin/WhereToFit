//
//  HomeReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import ReactorKit
import Foundation

final class HomeReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setWeatherSectionItem([HomeCollectionView.Item])
        case setRecommendSectionItem([HomeCollectionView.Item])
    }
    
    struct State {
        var isLoading: Bool = false
        var data: [HomeCollectionView.Section: [HomeCollectionView.Item]] = [:]
    }
    
    //MARK: Properties & Initialize
    private let dateService: DateService
    private let weatherRepository: WeatherRepositoryProtocol
    private let sportsRepository: SportsRepositoryProtocol
    
    init(
        dateService: DateService,
        weatherRepository: WeatherRepositoryProtocol,
        sportsRepository: SportsRepositoryProtocol
    ) {
        self.dateService = dateService
        self.weatherRepository = weatherRepository
        self.sportsRepository = sportsRepository
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return Observable.concat([
                .just(.setLoading(true)),
                makeWeatherSection(),
                makeRecommendSection(),
                .just(.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setWeatherSectionItem(let item):
            newState.data[.weather] = item
        case .setRecommendSectionItem(let item):
            newState.data[.recommend] = item
        }
        
        return newState
    }
}

extension HomeReactor {
    //TODO: schedule 정보
    private func makeWeatherSection() -> Observable<Mutation> {
        let weeklyDate = dateService.weeklyDate()
        let isNight = dateService.isNight()
        
        return weatherRepository
            .fetchWeather(latitude: 37.57, longitude: 127)
            .map { weather in
                let item = HomeCollectionView.WeatherSectionItem(
                    weeklyDate: weeklyDate,
                    weather: weather,
                    isNight: isNight
                )
                
                return Mutation.setWeatherSectionItem([HomeCollectionView.Item.weather(item)])
            }
            .asObservable()
    }
    
    private func makeRecommendSection() -> Observable<Mutation> {
        return sportsRepository.fetchPrograms(limit: 5, offset: 0, order: .ascending)
            .map { page in
                let programs = page.items
                let categories = programs.map { $0.sportsCategory }
                let items = categories.reduce([HomeCollectionView.Item]()) {
                    $0 + [HomeCollectionView.Item.recommend($1)]
                }
                return Mutation.setRecommendSectionItem(items)
            }
            .asObservable()
    }
}

final class SportsRepositoryExample: SportsRepositoryProtocol {
    private let samplePrograms: [Program] = [
        Program(
            id: 1,
            facilityName: "구미시민운동장",
            facilityLocation: "경상북도 구미시 박정희로 375",
            className: "성인 초급 배드민턴 교실",
            sport: "배드민턴",
            sportsCategory: .ballSports,
            classDescription: "배드민턴 기본 자세와 규칙을 배우는 입문 과정입니다.",
            targetAges: [.adult],
            levels: [.beginner],
            isDisabledAccessible: true,
            priceAmount: 50000,
            priceUnit: .month,
            priceNote: "라켓 대여 가능",
            days: ["월", "수", "금"],
            startTime: "19:00",
            endTime: "20:30",
            phoneNumber: "054-480-1234",
            reservationMethods: [.online, .phone],
            homepageURL: "https://www.gumi.go.kr"
        ),
        Program(
            id: 2,
            facilityName: "구미국민체육센터",
            facilityLocation: "경상북도 구미시 산책길 105",
            className: "아침 자유수영",
            sport: "수영",
            sportsCategory: .aquaticSports,
            classDescription: "출근 전 이용하기 좋은 성인 자유수영 프로그램입니다.",
            targetAges: [.adult],
            levels: [.all],
            isDisabledAccessible: false,
            priceAmount: 60000,
            priceUnit: .month,
            priceNote: nil,
            days: ["화", "목"],
            startTime: "07:00",
            endTime: "08:00",
            phoneNumber: "054-480-2233",
            reservationMethods: [.online, .visit],
            homepageURL: nil
        ),
        Program(
            id: 3,
            facilityName: "구미생활체육관",
            facilityLocation: "경상북도 구미시 체육공원로 45",
            className: "저녁 필라테스",
            sport: "필라테스",
            sportsCategory: .yogaPilates,
            classDescription: "코어 강화와 자세 교정을 위한 소그룹 필라테스입니다.",
            targetAges: [.adult],
            levels: [.beginner, .intermediate],
            isDisabledAccessible: true,
            priceAmount: 80000,
            priceUnit: .month,
            priceNote: "매트 개인 지참",
            days: ["월", "수"],
            startTime: "20:00",
            endTime: "21:00",
            phoneNumber: "054-480-3344",
            reservationMethods: [.phone],
            homepageURL: nil
        ),
        Program(
            id: 4,
            facilityName: "구미청소년문화센터",
            facilityLocation: "경상북도 구미시 문화로 12",
            className: "청소년 방송댄스",
            sport: "방송댄스",
            sportsCategory: .dance,
            classDescription: "기초 리듬감과 안무를 배우는 청소년 대상 댄스 수업입니다.",
            targetAges: [.youth],
            levels: [.beginner],
            isDisabledAccessible: false,
            priceAmount: 40000,
            priceUnit: .month,
            priceNote: nil,
            days: ["토"],
            startTime: "14:00",
            endTime: "15:30",
            phoneNumber: "054-480-4455",
            reservationMethods: [.online],
            homepageURL: nil
        ),
        Program(
            id: 5,
            facilityName: "구미복합스포츠센터",
            facilityLocation: "경상북도 구미시 복합로 70",
            className: "직장인 헬스PT",
            sport: "헬스PT",
            sportsCategory: .health,
            classDescription: "근력 향상과 체형 관리를 위한 개인 맞춤 운동입니다.",
            targetAges: [.adult],
            levels: [.all],
            isDisabledAccessible: true,
            priceAmount: 120000,
            priceUnit: .month,
            priceNote: "월 8회 기준",
            days: ["월", "화", "목"],
            startTime: "18:30",
            endTime: "21:30",
            phoneNumber: "054-480-5566",
            reservationMethods: [.phone, .visit],
            homepageURL: nil
        ),
        Program(
            id: 6,
            facilityName: "구미시니어체육센터",
            facilityLocation: "경상북도 구미시 시니어로 20",
            className: "시니어 생활체조",
            sport: "생활체조",
            sportsCategory: .gymnastics,
            classDescription: "관절 부담을 줄인 시니어 대상 생활체조 수업입니다.",
            targetAges: [.senior],
            levels: [.all],
            isDisabledAccessible: true,
            priceAmount: 20000,
            priceUnit: .month,
            priceNote: nil,
            days: ["화", "목"],
            startTime: "10:00",
            endTime: "11:00",
            phoneNumber: "054-480-6677",
            reservationMethods: [.visit],
            homepageURL: nil
        )
    ]
    
    func fetchFacilities(limit: Int, offset: Int, order: SearchOrder) -> RxSwift.Single<SupabasePage<Facility>> {
        return Single.just(.init(items: [], nextOffset: nil))
    }
    
    func searchFacilities(keyword: String, limit: Int, offset: Int, order: SearchOrder) -> RxSwift.Single<SupabasePage<Facility>> {
        return Single.just(.init(items: [], nextOffset: nil))
    }
    
    func fetchPrograms(limit: Int = 50, offset: Int = 0 , order: SearchOrder = .ascending) -> RxSwift.Single<SupabasePage<Program>> {
        return Single.just(page(from: samplePrograms, limit: limit, offset: offset, order: order))
    }
    
    func searchPrograms(keyword: String, limit: Int, offset: Int, order: SearchOrder) -> RxSwift.Single<SupabasePage<Program>> {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredPrograms = trimmedKeyword.isEmpty ? samplePrograms : samplePrograms.filter { program in
            program.className?.localizedCaseInsensitiveContains(trimmedKeyword) == true ||
            program.sport?.localizedCaseInsensitiveContains(trimmedKeyword) == true ||
            program.facilityName?.localizedCaseInsensitiveContains(trimmedKeyword) == true
        }
        
        return Single.just(page(from: filteredPrograms, limit: limit, offset: offset, order: order))
    }
    
    private func page(from programs: [Program], limit: Int, offset: Int, order: SearchOrder) -> SupabasePage<Program> {
        let sortedPrograms = programs.sorted { lhs, rhs in
            switch order {
            case .ascending:
                return (lhs.id ?? 0) < (rhs.id ?? 0)
            case .descending:
                return (lhs.id ?? 0) > (rhs.id ?? 0)
            }
        }
        
        let startIndex = max(0, offset)
        let endIndex = min(startIndex + max(0, limit), sortedPrograms.count)
        let items = startIndex < endIndex ? Array(sortedPrograms[startIndex..<endIndex]) : []
        let nextOffset = endIndex < sortedPrograms.count ? endIndex : nil
        
        return SupabasePage(items: items, nextOffset: nextOffset)
    }
}
