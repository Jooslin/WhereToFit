//
//  NetworkService.swift
//  WhereToFit
//
//  Created by 변예린 on 5/29/26.
//

import Foundation
import Alamofire

final class NetworkService: Sendable {
    private let supabaseBaseURL: String
    private let supabasePublishableKey: String
    private let weatherKey: String
    private let naverMapClientID: String
    private let naverMapClientSecret: String
    private let naverSearchClientID: String
    private let naverSearchClientSecret: String
    
    init(
        supabaseBaseURL: String = Bundle.main.supabaseBaseURL,
        supabasePublishableKey: String = Bundle.main.supabasePublishableKey,
        weatherKey: String = Bundle.main.openweatherKey,
        naverMapClientID: String = Bundle.main.naverMapClientID,
        naverMapClientSecret: String = Bundle.main.naverMapClientSecret,
        naverSearchClientID: String = Bundle.main.naverSearchClientID,
        naverSearchClientSecret: String = Bundle.main.naverSearchClientSecret
    ) {
        self.supabaseBaseURL = supabaseBaseURL
        self.supabasePublishableKey = supabasePublishableKey
        self.weatherKey = weatherKey
        self.naverMapClientID = naverMapClientID
        self.naverMapClientSecret = naverMapClientSecret
        self.naverSearchClientID = naverSearchClientID
        self.naverSearchClientSecret = naverSearchClientSecret
    }

}

nonisolated private struct NaverGeocodeResponse: Decodable, Sendable {
    let addresses: [NaverGeocodeAddress]
}

nonisolated private struct NaverGeocodeAddress: Decodable, Sendable {
    let roadAddress: String?
    let jibunAddress: String?
    let x: String
    let y: String
}

nonisolated struct NaverGeocodeLocation: Equatable, Sendable {
    let title: String
    let subtitle: String
    let coordinate: GeoCoordinate
}

nonisolated private struct NaverLocalSearchResponse: Decodable, Sendable {
    let items: [NaverLocalSearchItem]
}

nonisolated private struct NaverLocalSearchItem: Decodable, Sendable {
    let title: String
    let category: String
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String
}

struct SupabasePage<T> {
    let items: [T]
    let nextOffset: Int?
    let totalCount: Int?

    init(
        items: [T],
        nextOffset: Int?,
        totalCount: Int? = nil
    ) {
        self.items = items
        self.nextOffset = nextOffset
        self.totalCount = totalCount
    }
    
    var hasNextPage: Bool {
        nextOffset != nil
    }
}

enum SearchOrder: String {
    case ascending = "asc"
    case descending = "desc"
}

//MARK: Supabase
extension NetworkService {
    // supabase 전체 데이터 가져오기 메서드
    func fetchSupabaseData<T: Decodable & Sendable>(
        api: API,
        filters: Parameters = [:],
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending,
        includesTotalCount: Bool = false
    ) async throws -> SupabasePage<T> {
        guard let tableName = api.tableName else {
            throw NetworkServiceError.invalidEndpoint
        }

        var parameters = filters
        parameters["select"] = "*"
        parameters["order"] = "id.\(order.rawValue)"

        return try await requestSupabasePage(
            tableName: tableName,
            parameters: parameters,
            limit: limit,
            offset: offset,
            includesTotalCount: includesTotalCount
        )
    }

    // supabase 데이터 검색 메서드
    func fetchFilteredSupabaseData<T: Decodable & Sendable>(
        api: API,
        keyword: String,
        searchType: SearchType,
        order: SearchOrder,
        limit: Int = 50, // 한 페이지에 들어갈 데이터 수
        offset: Int = 0, // 현재 페이지 위치
        includesTotalCount: Bool = false
    ) async throws -> SupabasePage<T> {
        guard let tableName = api.tableName else {
            throw NetworkServiceError.invalidEndpoint
        }

        let parameters: Parameters = [
            "select": "*",
            searchType.rawValue: "ilike.*\(keyword)*",
            "order": "id.\(order.rawValue)"
        ]

        return try await requestSupabasePage(
            tableName: tableName,
            parameters: parameters,
            limit: limit,
            offset: offset,
            includesTotalCount: includesTotalCount
        )
    }

    // page 요청 메서드
    private func requestSupabasePage<T: Decodable & Sendable>(
        tableName: String,
        parameters: Parameters,
        limit: Int,
        offset: Int,
        includesTotalCount: Bool
    ) async throws -> SupabasePage<T> {
        guard !supabaseBaseURL.isEmpty,
              !supabaseBaseURL.contains("$("),
              !supabasePublishableKey.isEmpty,
              !supabasePublishableKey.contains("$(") else {
            throw NetworkServiceError.missingSupabaseConfiguration
        }

        guard limit > 0, offset >= 0 else {
            throw NetworkServiceError.invalidPaginationParameter
        }

        let baseURL = supabaseBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = "\(baseURL)/rest/v1/\(tableName)"
        var headers: HTTPHeaders = [
            "apikey": supabasePublishableKey,
            "Accept": "application/json"
        ]
        if includesTotalCount {
            headers.add(name: "Prefer", value: "count=exact")
        }
        var parameters = parameters
        parameters["limit"] = limit + 1
        parameters["offset"] = offset

        let response = await AF.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: headers
        )
            .validate()
            .serializingDecodable([T].self)
            .response

        let rows = try response.result.get()
        let totalCount = Self.totalCount(
            from: response.response?.value(forHTTPHeaderField: "Content-Range")
        )

        let hasNextPage = rows.count > limit
        let items = hasNextPage ? Array(rows.prefix(limit)) : rows
        let nextOffset = hasNextPage ? offset + limit : nil // 다음 페이지가 존재한다면 다음 Offset을 반환, 없다면 nil 반환

        return SupabasePage(
            items: items, // 현재 페이지 데이터들
            nextOffset: nextOffset, // 다음 페이지 존재 여부 + offset
            totalCount: totalCount
        )
    }

    private static func totalCount(from contentRange: String?) -> Int? {
        guard let totalText = contentRange?.split(separator: "/").last,
              totalText != "*" else {
            return nil
        }

        return Int(totalText)
    }
}

//MARK: API Networking
extension NetworkService {
    func fetchWeatherData(latitude: Double, longitude: Double) async throws -> CurrentWeatherDTO {
        guard !weatherKey.isEmpty,
              !weatherKey.contains("$(") else {
            throw NetworkServiceError.missingOpenWeatherConfiguration
        }

        guard let baseUrl = API.weather.baseUrl else {
            throw NetworkServiceError.invalidEndpoint
        }

        let params: Parameters = [
            "lat": latitude,
            "lon": longitude,
            "appid": weatherKey,
            "units": "metric",
            "lang": "kr"
        ]
        
        return try await AF.request(
            baseUrl,
            method: .get,
            parameters: params,
            encoding: URLEncoding.queryString
        )
            .validate()
            .serializingDecodable(CurrentWeatherDTO.self)
            .value
    }

    func fetchNaverGeocode(query: String) async throws -> GeoCoordinate? {
        try await fetchNaverGeocodeLocations(query: query).first?.coordinate
    }

    func fetchNaverGeocodeLocations(query: String) async throws -> [NaverGeocodeLocation] {
        guard !naverMapClientID.isEmpty,
              !naverMapClientID.contains("$("),
              !naverMapClientSecret.isEmpty,
              !naverMapClientSecret.contains("$(") else {
            throw NetworkServiceError.missingNaverMapConfiguration
        }

        guard let baseUrl = API.naverGeocode.baseUrl else {
            throw NetworkServiceError.invalidEndpoint
        }

        let headers: HTTPHeaders = [
            "x-ncp-apigw-api-key-id": naverMapClientID,
            "x-ncp-apigw-api-key": naverMapClientSecret
        ]
        let parameters: Parameters = [
            "query": query
        ]

        let response = try await AF.request(
            baseUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: headers
        )
            .validate()
            .serializingDecodable(NaverGeocodeResponse.self)
            .value

        return response.addresses.compactMap { address in
            guard let longitude = Double(address.x),
                  let latitude = Double(address.y) else {
                return nil
            }

            let title = address.roadAddress?.isEmpty == false
                ? address.roadAddress ?? ""
                : address.jibunAddress ?? query
            let subtitle = address.jibunAddress?.isEmpty == false
                ? address.jibunAddress ?? "네이버 지도"
                : "네이버 지도"

            return NaverGeocodeLocation(
                title: title,
                subtitle: subtitle,
                coordinate: GeoCoordinate(latitude: latitude, longitude: longitude)
            )
        }
    }

    func fetchNaverLocalSearchLocations(query: String) async throws -> [NaverGeocodeLocation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        guard !naverSearchClientID.isEmpty,
              !naverSearchClientID.contains("$("),
              !naverSearchClientSecret.isEmpty,
              !naverSearchClientSecret.contains("$(") else {
            throw NetworkServiceError.missingNaverSearchConfiguration
        }

        guard let baseUrl = API.naverLocalSearch.baseUrl else {
            throw NetworkServiceError.invalidEndpoint
        }

        let headers: HTTPHeaders = [
            "X-Naver-Client-Id": naverSearchClientID,
            "X-Naver-Client-Secret": naverSearchClientSecret
        ]
        let parameters: Parameters = [
            "query": trimmedQuery,
            "display": 5,
            "start": 1,
            "sort": "random"
        ]

        let response = try await AF.request(
            baseUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: headers
        )
            .validate()
            .serializingDecodable(NaverLocalSearchResponse.self)
            .value

        return response.items.compactMap { item in
            guard let longitude = Self.naverLocalLongitude(from: item.mapx),
                  let latitude = Self.naverLocalLatitude(from: item.mapy) else {
                return nil
            }

            let title = item.title.removingHTMLTags
            let address = item.roadAddress.isEmpty ? item.address : item.roadAddress
            let subtitle = [item.category.removingHTMLTags, address]
                .filter { $0.isEmpty == false }
                .joined(separator: " · ")

            return NaverGeocodeLocation(
                title: title,
                subtitle: subtitle.isEmpty ? "네이버 지역 검색" : subtitle,
                coordinate: GeoCoordinate(latitude: latitude, longitude: longitude)
            )
        }
    }

    private static func naverLocalLongitude(from value: String) -> Double? {
        naverLocalWGS84Coordinate(from: value, validRange: 120...135)
    }

    private static func naverLocalLatitude(from value: String) -> Double? {
        naverLocalWGS84Coordinate(from: value, validRange: 30...45)
    }

    private static func naverLocalWGS84Coordinate(
        from value: String,
        validRange: ClosedRange<Double>
    ) -> Double? {
        guard let rawValue = Double(value) else { return nil }

        // Naver Local Search returns WGS84 coordinates scaled by 10,000,000.
        let coordinate = abs(rawValue) > 1_000 ? rawValue / 10_000_000 : rawValue
        guard validRange.contains(coordinate) else { return nil }
        return coordinate
    }
}

//MARK: Util
extension NetworkService {
    enum NetworkServiceError: LocalizedError {
        case missingSupabaseConfiguration
        case missingOpenWeatherConfiguration
        case missingNaverMapConfiguration
        case missingNaverSearchConfiguration
        case invalidEndpoint
        case invalidPaginationParameter

        var errorDescription: String? {
            switch self {
            case .missingSupabaseConfiguration:
                return "Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to Info.plist or build settings."
            case .missingOpenWeatherConfiguration:
                return "OpenWeather configuration is missing. Add OPENWEATHER_KEY to Info.plist or build settings."
            case .missingNaverMapConfiguration:
                return "Naver Maps configuration is missing. Add NAVER_MAP_CLIENT_ID and NAVER_MAP_CLIENT_SECRET to build settings."
            case .missingNaverSearchConfiguration:
                return "Naver Search configuration is missing. Add NAVER_SEARCH_CLIENT_ID and NAVER_SEARCH_CLIENT_SECRET to build settings."
            case .invalidEndpoint:
                return "The selected API endpoint is not configured."
            case .invalidPaginationParameter:
                return "Pagination limit must be greater than 0 and offset must be 0 or greater."
            }
        }
    }

    enum API {
        case weather
        case naverGeocode
        case naverLocalSearch
        case facility
        case classInfo
        case sportRecommendationRules
        
        var baseUrl: String? {
            switch self {
            case .weather:
                return "https://api.openweathermap.org/data/2.5/weather"
            case .naverGeocode:
                return "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"
            case .naverLocalSearch:
                return "https://openapi.naver.com/v1/search/local.json"
            case .facility, .classInfo, .sportRecommendationRules:
                return nil
            }
        }
        
        var tableName: String? {
            switch self {
            case .weather, .naverGeocode, .naverLocalSearch:
                return nil
            case .facility:
                return "public_facilities"
            case .classInfo:
                return "class_information"
            case .sportRecommendationRules:
                return "sport_recommendation_rules"
            }
        }
    }
    
    enum SearchType: String {
        case facilityID = "id"
        case facilityName = "facility_name"
        case className = "class_name"
    }
}

private extension Bundle {
    var supabaseBaseURL: String {
        object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    }

    var supabasePublishableKey: String {
        object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? ""
    }
    
    var openweatherKey: String {
        object(forInfoDictionaryKey: "OPENWEATHER_KEY") as? String ?? ""
    }

    var naverMapClientID: String {
        object(forInfoDictionaryKey: "NMFNcpKeyId") as? String ?? ""
    }

    var naverMapClientSecret: String {
        object(forInfoDictionaryKey: "NAVER_MAP_CLIENT_SECRET") as? String ?? ""
    }

    var naverSearchClientID: String {
        object(forInfoDictionaryKey: "NAVER_SEARCH_CLIENT_ID") as? String ?? ""
    }

    var naverSearchClientSecret: String {
        object(forInfoDictionaryKey: "NAVER_SEARCH_CLIENT_SECRET") as? String ?? ""
    }
}

private extension String {
    var removingHTMLTags: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
