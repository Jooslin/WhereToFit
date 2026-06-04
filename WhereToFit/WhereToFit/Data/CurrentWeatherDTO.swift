//
//  CurrentWeatherDTO.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import Foundation

nonisolated struct CurrentWeatherDTO: Decodable, Sendable {
    let weather: [WeatherConditionDTO]
    let base: String?
    let main: MainDTO
    let visibility: Int? // 가시거리

    let dt: Int // 예보 시각
    let timezone: Int?
    let id: Int?
    let name: String?
}

extension CurrentWeatherDTO {
    nonisolated struct WeatherConditionDTO: Decodable, Sendable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    nonisolated struct MainDTO: Decodable, Sendable {
        let temperature: Double
        let feelsLike: Double
        let minimumTemperature: Double?
        let maximumTemperature: Double?
        let humidity: Int

        enum CodingKeys: String, CodingKey {
            case temperature = "temp"
            case feelsLike = "feels_like"
            case minimumTemperature = "temp_min"
            case maximumTemperature = "temp_max"
            case humidity
        }
    }
}
