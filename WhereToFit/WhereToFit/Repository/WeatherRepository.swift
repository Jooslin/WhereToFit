//
//  WeatherRepository.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

/**
 날씨 관련 Repository에 적용하는 프로토콜입니다.  구현체에서 채택하여 사용합니다.
 
 구현체는 아래와 같이 사용할 수 있습니다.
 ```swift
 private lazy var weatherRepository = WeatherRepository(networkService: networkService) // 실제 사용 시 의존성 주입 Flow에서 진행

 let weather: Weather = try await weatherRepository.fetchWeather(latitude: 37.5710, longitude: 127.9770) // 광화문 현재 날씨
 ```
*/
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
