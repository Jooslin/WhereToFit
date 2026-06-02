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
        case sun, rain, cloud, snow, wind
    }
}
