//
//  HomeReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import ReactorKit

final class HomeReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setWeatherSectionItem([HomeCollectionView.Item])
    }
    
    struct State {
        var isLoading: Bool = false
        var data: [HomeCollectionView.Section: [HomeCollectionView.Item]] = [:]
    }
    
    //MARK: Properties & Initialize
    private let dateService: DateService
    private let weatherRepository: WeatherRepository
    
    init(dateService: DateService, repository: WeatherRepository) {
        self.dateService = dateService
        self.weatherRepository = repository
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return Observable.concat([
                .just(.setLoading(true)),
                makeWeatherSection(),
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
}
