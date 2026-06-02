//
//  WeatherRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather
}

final class WeatherRepository: WeatherRepositoryProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let dto = try await networkService.fetchWeatherData(
            latitude: latitude,
            longitude: longitude
        )
        
        return Weather(dto: dto)
    }
}
