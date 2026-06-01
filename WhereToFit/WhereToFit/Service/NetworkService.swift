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
    
    // supabase에 적재된 테이블의 전체 데이터 조회 메서드 - 강좌 정보는 원본 데이터 양이 많으므로 조회 제한이 걸릴 수 있음
    func fetchAllSupabaseData<T: Decodable>(api: API) async throws -> [T] {
        guard !supabaseBaseURL.isEmpty,
              !supabaseBaseURL.contains("$("),
              !supabasePublishableKey.isEmpty,
              !supabasePublishableKey.contains("$(") else {
            throw NetworkServiceError.missingSupabaseConfiguration
        }

        guard let endpoint = api.endpoint else {
            throw NetworkServiceError.invalidEndpoint
        }

        let baseURL = supabaseBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = "\(baseURL)/rest/v1/\(endpoint)"
        let headers: HTTPHeaders = [
            "apikey": supabasePublishableKey,
            "Authorization": "Bearer \(supabasePublishableKey)",
            "Accept": "application/json"
        ]

        return try await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingDecodable([T].self)
            .value
    }

}

extension NetworkService {
    enum NetworkServiceError: LocalizedError {
        case missingSupabaseConfiguration
        case invalidEndpoint

        var errorDescription: String? {
            switch self {
            case .missingSupabaseConfiguration:
                return "Supabase configuration is missing. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to Info.plist or build settings."
            case .invalidEndpoint:
                return "The selected API endpoint is not configured."
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
        
        var endpoint: String? {
            switch self {
            case .weather:
                return nil
            case .facility:
                return "public_facilities?select=*&order=facility_name.asc"
            case .classInfo:
                return "class_information?select=*&order=id.asc"
            }
        }
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
