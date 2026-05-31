//
//  NetworkService.swift
//  WhereToFit
//
//  Created by 변예린 on 5/29/26.
//

import Foundation
import Alamofire
import FirebaseCore
import FirebaseFirestore

final class NetworkService {
    private let firestore: Firestore?
    
    init(firestore: Firestore? = nil) {
        self.firestore = firestore
    }
    
    func fetchPublicFacilities() async throws -> [PublicFacilityDocument] {
        guard FirebaseApp.app() != nil else {
            throw NetworkServiceError.firebaseNotConfigured
        }
        
        guard let collectionPath = API.facility.collectionPath else {
            throw NetworkServiceError.invalidEndpoint
        }

        let firestore = firestore ?? Firestore.firestore()
        let snapshot = try await firestore.collection(collectionPath).getDocuments()
        
        return snapshot.documents.map {
            PublicFacilityDocument(id: $0.documentID, data: $0.data())
        }
    }
}

extension NetworkService {
    struct PublicFacilityDocument {
        let id: String
        let data: [String: Any]
    }

    enum NetworkServiceError: LocalizedError {
        case firebaseNotConfigured
        case invalidEndpoint

        var errorDescription: String? {
            switch self {
            case .firebaseNotConfigured:
                return "Firebase is not configured. Call FirebaseApp.configure() before fetching Firestore data."
            case .invalidEndpoint:
                return "The selected API endpoint is not configured."
            }
        }
    }

    enum API {
        case weather
        case facility
        
        var baseUrl: String? {
            switch self {
            case .weather:
                return "https://api.openweathermap.org/data/2.5/weather"
            case .facility:
                return nil
            }
        }
        
        var collectionPath: String? {
            switch self {
            case .weather:
                return nil
            case .facility:
                return "publicFacilities"
            }
        }
    }
}
