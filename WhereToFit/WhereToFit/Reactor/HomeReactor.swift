//
//  HomeReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import ReactorKit
import UIKit

final class HomeReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setUserProfile(UserProfile?)
        case setCurrentLocation(UserLocation?)
        case setLocationTitle(String)
        case setProgramSectionTitle(String)
        
        case setWeatherSectionItem([HomeCollectionView.Item])
        case setRecommendSectionItem([HomeCollectionView.Item])
        case setRecommendReasonSectionItem([HomeCollectionView.Item])
        case setOnboardingSectionItem([HomeCollectionView.Item])
        case setProgramSectionItem([HomeCollectionView.Item])
    }
    
    struct State {
        var isLoading: Bool = false
        var userProfile: UserProfile?
        var currentLocation: UserLocation?
        var locationTitle: String = HomeReactor.defaultLocationTitle
        var programSectionTitle: String = HomeReactor.defaultProgramSectionTitle
        var data: [HomeCollectionView.Section: [HomeCollectionView.Item]] = [:]
    }
    
    //MARK: Properties & Initialize
    private let userStore: UserStoreProtocol
    private let dateService: DateService
    private let weatherRepository: WeatherRepositoryProtocol
    private let sportsRepository: SportsRepositoryProtocol
    
    private let fetchRegisteredProgramUseCase: FetchRegisteredProgramsUseCase
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let fetchSelectedUserLocationUseCase: FetchSelectedUserLocationUseCase
    private let recommendSportsUseCase: RecommendSportsUseCase
    private let fetchHomeProgramRecommendationsUseCase: FetchHomeProgramRecommendationsUseCase
    private let generateHomeRecommendationCopyUseCase: GenerateHomeRecommendationCopyUseCase
    
    init(
        userStore: UserStoreProtocol,
        dateService: DateService,
        weatherRepository: WeatherRepositoryProtocol,
        sportsRepository: SportsRepositoryProtocol,
        fetchRegisteredProgramUseCase: FetchRegisteredProgramsUseCase = FetchRegisteredProgramsUseCase(repository: CoreDataRegisteredProgramRepository()),
        fetchUserProfileUseCase: FetchUserProfileUseCase = FetchUserProfileUseCase(
            repository: CoreDataUserProfileRepository()
        ),
        fetchSelectedUserLocationUseCase: FetchSelectedUserLocationUseCase = FetchSelectedUserLocationUseCase(
            repository: CoreDataUserLocationRepository()
        ),
        recommendSportsUseCase: RecommendSportsUseCase = RecommendSportsUseCase(
            repository: SportRecommendationRuleRepository()
        ),
        fetchHomeProgramRecommendationsUseCase: FetchHomeProgramRecommendationsUseCase? = nil,
        generateHomeRecommendationCopyUseCase: GenerateHomeRecommendationCopyUseCase = GenerateHomeRecommendationCopyUseCase(
            repository: HomeRecommendationCopyRepository()
        )
    ) {
        self.userStore = userStore
        self.dateService = dateService
        self.weatherRepository = weatherRepository
        self.sportsRepository = sportsRepository
        self.fetchRegisteredProgramUseCase = fetchRegisteredProgramUseCase
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.fetchSelectedUserLocationUseCase = fetchSelectedUserLocationUseCase
        self.recommendSportsUseCase = recommendSportsUseCase
        self.fetchHomeProgramRecommendationsUseCase = fetchHomeProgramRecommendationsUseCase ?? FetchHomeProgramRecommendationsUseCase(
            sportsRepository: sportsRepository,
            recommendSportsUseCase: recommendSportsUseCase
        )
        self.generateHomeRecommendationCopyUseCase = generateHomeRecommendationCopyUseCase
    }
    
    //MARK: Reactor func
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return Observable.concat([
                .just(.setLoading(true)),
                makeHomeContent(),
                .just(.setLoading(false))
            ])
        }
    }
    
    // observe하고 있는 프로퍼티에 변경이 있을 때 동작
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let profileMutation = userStore.userProfile
            .map { profile -> Mutation in
                Mutation.setUserProfile(profile)
            }
        
        let locationMutation = userStore.currentLocation
            .map { location -> Mutation in
                .setCurrentLocation(location)
            }
        
        return Observable.merge(mutation, profileMutation, locationMutation)
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setUserProfile(let profile):
            newState.userProfile = profile
        case .setCurrentLocation(let location):
            newState.currentLocation = location
        case .setLocationTitle(let title):
            newState.locationTitle = title
        case .setProgramSectionTitle(let title):
            newState.programSectionTitle = title
        case .setWeatherSectionItem(let item):
            newState.data[.weather] = item
        case .setRecommendSectionItem(let item):
            newState.data[.recommend] = item
        case .setRecommendReasonSectionItem(let item):
            newState.data[.recommendReason] = item
        case .setOnboardingSectionItem(let item):
            newState.data[.onboarding] = item
        case .setProgramSectionItem(let item):
            newState.data[.program] = item
        }
        
        return newState
    }
}

extension HomeReactor {
    private struct HomeContext {
        let profile: UserProfile?
        let location: UserLocation?
        
        var didCompleteOnboarding: Bool {
            profile != nil
        }
    }
    
    static let defaultLocationTitle = "종로구"
    static let defaultProgramSectionTitle = "주변 프로그램"
    private static let pendingCategoryRecommendationTitle = "추천 프로그램"
    private static let defaultLocationAddress = "서울 종로구 효자로 12 국립고궁박물관"
    private static let defaultLocationLatitude = 37.57665
    private static let defaultLocationLongitude = 126.97498
    
    private func makeHomeContent() -> Observable<Mutation> {
        fetchHomeContext()
            .asObservable()
            .flatMap { [weak self] context -> Observable<Mutation> in
                guard let self else { return .empty() }
                
                self.userStore.setProfile(context.profile)
                if let location = context.location {
                    self.userStore.setCurrnetLocation(location)
                }
                
                let address = context.location?.address ?? Self.defaultLocationAddress
                let locationTitle = Self.locationTitle(from: address)
                let programSectionTitle = context.didCompleteOnboarding ? Self.pendingCategoryRecommendationTitle : Self.defaultProgramSectionTitle
                
                return Observable.concat([
                    .just(.setUserProfile(context.profile)),
                    .just(.setCurrentLocation(context.location)),
                    .just(.setLocationTitle(locationTitle)),
                    .just(.setProgramSectionTitle(programSectionTitle)),
                    self.makeWeatherSection(location: context.location),
                    self.makeRecommendationContent(context: context),
                    self.makeOnboardingSection(context: context),
                    self.makeProgramSection(context: context)
                ])
            }
            .catch { [weak self] _ in
                guard let self else { return .just(.setLoading(false)) }
                
                self.userStore.setProfile(nil)
                
                return Observable.concat([
                    .just(.setUserProfile(nil)),
                    .just(.setCurrentLocation(nil)),
                    .just(.setLocationTitle(Self.defaultLocationTitle)),
                    .just(.setProgramSectionTitle(Self.defaultProgramSectionTitle)),
                    self.makeWeatherSection(location: nil),
                    self.makeRecommendationContent(context: HomeContext(profile: nil, location: nil)),
                    self.makeOnboardingSection(context: HomeContext(profile: nil, location: nil)),
                    self.makeProgramSection(context: HomeContext(profile: nil, location: nil))
                ])
            }
    }
    
    private func fetchHomeContext() -> Single<HomeContext> {
        fetchUserProfileUseCase.execute()
            .flatMap { [fetchSelectedUserLocationUseCase] profile -> Single<HomeContext> in
                guard let profile else {
                    return .just(HomeContext(profile: nil, location: nil))
                }
                
                return fetchSelectedUserLocationUseCase.execute(userProfileID: profile.id)
                    .map { location in
                        HomeContext(profile: profile, location: location)
                    }
            }
    }
    
    //TODO: schedule 정보
    private func makeWeatherSection(location: UserLocation?) -> Observable<Mutation> {
        let weeklyDate = dateService.weeklyDate()
        let isNight = dateService.isNight()
        let latitude = location?.latitude ?? Self.defaultLocationLatitude
        let longitude = location?.longitude ?? Self.defaultLocationLongitude
        
        let weather = weatherRepository
            .fetchWeather(latitude: latitude, longitude: longitude)
        
        let program = fetchRegisteredProgramUseCase.execute()
        
        return weatherRepository
            .fetchWeather(latitude: latitude, longitude: longitude)
            .map { weather in
                let item = HomeCollectionView.WeatherSectionItem(
                    weeklyDate: weeklyDate,
                    weather: weather,
                    isNight: isNight
                )
                
                return Mutation.setWeatherSectionItem([HomeCollectionView.Item.weather(item)])
            }
            .asObservable()
            .catch { _ in .just(.setWeatherSectionItem([])) }
    }
    
    private func makeRecommendationContent(context: HomeContext) -> Observable<Mutation> {
        guard let profile = context.profile else {
            return Observable.concat([
                .just(.setRecommendSectionItem([])),
                .just(.setRecommendReasonSectionItem([]))
            ])
        }
        
        return recommendSportsUseCase.execute(profile: profile)
            .asObservable()
            .flatMap { [generateHomeRecommendationCopyUseCase] sports -> Observable<Mutation> in
                let recommendMutation = Mutation.setRecommendSectionItem(
                    sports.map(HomeCollectionView.Item.recommend)
                )
                
                guard sports.isEmpty == false else {
                    return Observable.concat([
                        .just(recommendMutation),
                        .just(.setRecommendReasonSectionItem([]))
                    ])
                }
                
                let copyMutation = generateHomeRecommendationCopyUseCase
                    .execute(profile: profile, recommendedSports: sports)
                    .asObservable()
                    .flatMap { copy -> Observable<Mutation> in
                        Observable.from([
                            .setProgramSectionTitle(copy.categoryTitle),
                            .setRecommendReasonSectionItem([
                                .recommendReason(copy.personalizedReason)
                            ])
                        ])
                    }
                    .catch { _ in .just(.setRecommendReasonSectionItem([])) }
                
                return Observable.concat([
                    .just(recommendMutation),
                    copyMutation
                ])
            }
            .catch { _ in
                Observable.concat([
                    .just(.setRecommendSectionItem([])),
                    .just(.setRecommendReasonSectionItem([]))
                ])
            }
    }
    
    private func makeOnboardingSection(context: HomeContext) -> Observable<Mutation> {
        let item: [HomeCollectionView.Item] = context.didCompleteOnboarding ? [] : [.onboarding]
        return .just(.setOnboardingSectionItem(item))
    }
    
    private func makeProgramSection(context: HomeContext) -> Observable<Mutation> {
        fetchHomeProgramRecommendationsUseCase.execute(
            profile: context.profile,
            location: context.location
        )
            .asObservable()
            .map { programs in
                var seenProgramIDs = Set<Int>()
                let items = programs.enumerated().compactMap { index, recommendedProgram -> HomeCollectionView.Item? in
                    let programID = recommendedProgram.program.id ?? -(index + 1)
                    
                    guard seenProgramIDs.insert(programID).inserted else {
                        return nil
                    }
                    
                    return HomeCollectionView.Item.program(
                        HomeCollectionView.ProgramSectionItem(
                            id: programID,
                            imageName: recommendedProgram.program.sportsCategory.imageName,
                            matchRate: recommendedProgram.matchRate.map(Double.init),
                            place: Self.place(for: recommendedProgram.facility),
                            name: recommendedProgram.program.className ?? recommendedProgram.program.sport ?? "",
                            facility: recommendedProgram.facility
                        )
                    )
                }
                
                return .setProgramSectionItem(items)
            }
            .catch { _ in .just(.setProgramSectionItem([])) }
    }
    
    private static func place(for facility: Facility) -> String {
        let text = [
            facility.facilityName,
            facility.locationName,
            facility.facilityType,
            facility.extraFacilityInfo
        ]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let outdoorKeywords = ["축구장", "풋살장", "야구장", "테니스장", "게이트볼장", "파크골프", "국궁장"]
        
        return outdoorKeywords.contains { text.contains($0) } ? "야외" : "실내"
    }
    
    static func locationTitle(from address: String) -> String {
        let parts = address
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        
        return parts.dropFirst().first ?? defaultLocationTitle
    }
}
