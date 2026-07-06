//
//  ReservationMethod.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import Foundation

nonisolated
enum ReservationMethod: Equatable {
    case online
    case phone
    case visit
    case app
    case email
    case inquire
    
    init(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch value {
        case "온라인", "인터넷", "홈페이지", "웹":
            self = .online
        case "전화", "유선":
            self = .phone
        case "방문", "현장":
            self = .visit
        case "앱", "모바일":
            self = .app
        case "이메일", "메일":
            self = .email
        default:
            self = .inquire
        }
    }
}

nonisolated extension ReservationMethod {
    var title: String {
        switch self {
        case .online: return "온라인"
        case .phone: return "전화"
        case .visit: return "방문"
        case .app: return "앱"
        case .email: return "이메일"
        case .inquire: return "문의"
        }
    }

    static func parse(_ rawValue: String?) -> [ReservationMethod] {
        guard let rawValue else {
            return []
        }
        
        return rawValue
            .split { character in
                character == "," || character == "/" || character == "|"
            }
            .map(String.init)
            .map(ReservationMethod.init)
    }
}
