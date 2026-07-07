//
//  WeatherRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 7/7/26.
//

import RxSwift

final class WeatherRepository: WeatherRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> Single<Weather> {
        Single.async { [networkService] in
            let dto = try await networkService.fetchWeatherData(
                latitude: latitude,
                longitude: longitude
            )
            
            return Weather(dto: dto)
        }
    }
}
