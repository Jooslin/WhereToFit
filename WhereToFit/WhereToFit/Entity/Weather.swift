//
//  Weather.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

struct Weather {
    let category: WeatherCategory
    let description: String // 날씨 부가설명
    let temperature: Double // 현재 온도
    
    enum WeatherCategory {
        case thunderstorm
        case drizzle
        case sun
        case rain
        case cloud
        case snow
        case wind
        case atmosphere // 대기 관련 - ex. 황사, 안개 등
        case unknown
    }
}

extension Weather {
    init(dto: CurrentWeatherDTO) {
        let primaryCondition = dto.weather.first
        
        self.category = WeatherCategory(conditionId: primaryCondition?.id)
        self.description = primaryCondition?.description ?? ""
        self.temperature = dto.main.temperature
    }
}

private extension Weather.WeatherCategory {
    init(conditionId: Int?) {
        guard let conditionId else {
            self = .unknown
            return
        }
        
        switch conditionId {
        case 200...299:
            self = .thunderstorm
        case 300...399:
            self = .drizzle
        case 500...599:
            self = .rain
        case 600...699:
            self = .snow
        case 700...799:
            self = .atmosphere
        case 800:
            self = .sun
        case 801...804:
            self = .cloud
        default:
            self = .unknown
        }
    }
}
