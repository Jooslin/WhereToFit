//
//  Location.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

nonisolated
struct Location: Hashable {
    let buttonType: LocationButtonType
    let name: String
    let address: String
    let isSelected: Bool
    let latitude: Double
    let longitude: Double
    
    enum LocationButtonType {
        case myHome
        case office
        case additional
        
        var title: String {
            switch self {
            case .myHome: "우리집"
            case .office: "회사"
            case .additional: "추가"
            }
        }
    }
}
