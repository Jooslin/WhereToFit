//
//  NetworkService.swift
//  WhereToFit
//
//  Created by 변예린 on 5/29/26.
//

import Foundation
import Alamofire

final class NetworkService {
    private let supabaseBaseURL: String
    private let supabasePublishableKey: String
    
    init(
        supabaseBaseURL: String = Bundle.main.supabaseBaseURL,
        supabasePublishableKey: String = Bundle.main.supabasePublishableKey
    ) {
        self.supabaseBaseURL = supabaseBaseURL
        self.supabasePublishableKey = supabasePublishableKey
    }

}

//MARK: Supabase
extension NetworkService {
    // supabase 전체 데이터 가져오기 메서드
    func fetchSupabaseData<T: Decodable>(
        api: API,
        limit: Int = 50,
        offset: Int = 0,
        order: SearchOrder = .ascending
    ) async throws -> SupabasePage<T> {
        guard let tableName = api.tableName else {
            throw NetworkServiceError.invalidEndpoint
        }

        let parameters: Parameters = [
            "select": "*",
            "order": "id.\(order.rawValue)"
        ]

        return try await requestSupabasePage(
            tableName: tableName,
            parameters: parameters,
            limit: limit,
            offset: offset
        )
    }

    // supabase 데이터 검색 메서드
    func fetchFilteredSupabaseData<T: Decodable>(
        api: API,
        keyword: String,
        searchType: SearchType,
        order: SearchOrder,
        limit: Int = 50,
        offset: Int = 0
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
            offset: offset
        )
    }

    // page 요청 메서드
    private func requestSupabasePage<T: Decodable>(
        tableName: String,
        parameters: Parameters,
        limit: Int,
        offset: Int
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
        let headers: HTTPHeaders = [
            "apikey": supabasePublishableKey,
            "Accept": "application/json"
        ]
        var parameters = parameters
        parameters["limit"] = limit + 1
        parameters["offset"] = offset

        let rows = try await AF.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            headers: headers
        )
            .validate()
            .serializingDecodable([T].self)
            .value

        let hasNextPage = rows.count > limit
        let items = hasNextPage ? Array(rows.prefix(limit)) : rows
        let nextOffset = hasNextPage ? offset + limit : nil

        return SupabasePage(
            items: items,
            nextOffset: nextOffset
        )
    }
}

//MARK: Util
extension NetworkService {
    enum NetworkServiceError: LocalizedError {
        case missingSupabaseConfiguration
        case invalidEndpoint
        case invalidPaginationParameter

        var errorDescription: String? {
            switch self {
            case .missingSupabaseConfiguration:
                return "Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to Info.plist or build settings."
            case .invalidEndpoint:
                return "The selected API endpoint is not configured."
            case .invalidPaginationParameter:
                return "Pagination limit must be greater than 0 and offset must be 0 or greater."
            }
        }
    }

    enum API {
        case weather
        case facility
        case classInfo
        
        var baseUrl: String? {
            switch self {
            case .weather:
                return "https://api.openweathermap.org/data/2.5/weather"
            case .facility, .classInfo:
                return nil
            }
        }
        
        var tableName: String? {
            switch self {
            case .weather:
                return nil
            case .facility:
                return "public_facilities"
            case .classInfo:
                return "class_information"
            }
        }
    }
    
    struct SupabasePage<T> {
        let items: [T]
        let nextOffset: Int?

        var hasNextPage: Bool {
            nextOffset != nil
        }
    }
    
    enum SearchType: String {
        case facilityName = "facility_name"
        case className = "class_name"
    }
    
    enum SearchOrder: String {
        case ascending = "asc"
        case descending = "desc"
    }
}

private extension Bundle {
    var supabaseBaseURL: String {
        object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    }

    var supabasePublishableKey: String {
        object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? ""
    }
}
