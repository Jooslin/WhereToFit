//
//  Program.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import Foundation

nonisolated
struct Program: Hashable {
    let id: Int?
    let facilityName: String? // 시설 이름
    let facilityLocation: String? // 시설 소재지
    
    let className: String? // 프로그램 이름
    let sport: String? // 종목
    let sportsCategory: SportsCategory // 종목 카테고리
    let classDescription: String? // 프로그램 설명
    
    let targetAges: [ProgramTargetAge] // 대상 연령
    let levels: [ProgramLevel] // 대상 운동 수준
    let isDisabledAccessible: Bool? // 장애인 가능 여부
    
    let priceAmount: Int? // 가격
    let priceUnit: PriceUnit? // 가격 기준 시간 단위
    let priceNote: String? // 가격 특이사항 - ex. 일 10인 이상 시 가격
    
    let days: [String] // 프로그램 요일
    let startTime: String? // 시작 시각
    let endTime: String? // 종료 시각
    
    let phoneNumber: String? // 문의 전화
    let reservationMethods: [ReservationMethod] // 예약 방법
    let homepageURL: String?
}

extension Program {
    init(dto: ClassInformationDTO) {
        self.id = dto.id
        self.facilityName = dto.facilityName
        self.facilityLocation = dto.facilityLocation
        
        self.className = dto.className
        self.sport = dto.sport
        self.sportsCategory = SportsCategory(sport: dto.sport)
        self.classDescription = dto.classDescription
        
        self.targetAges = dto.targetAges?.map(ProgramTargetAge.init) ?? []
        self.levels = dto.levels?.map(ProgramLevel.init) ?? []
        self.isDisabledAccessible = dto.isDisabledAccessible

        self.priceAmount = dto.priceAmount
        self.priceUnit = dto.priceUnit.map { PriceUnit($0) }
        self.priceNote = dto.priceNote
        
        self.days = dto.days ?? []
        self.startTime = dto.startTime
        self.endTime = dto.endTime
        
        self.phoneNumber = dto.phoneNumber
        self.reservationMethods = dto.reservationMethods?.map(ReservationMethod.init) ?? []
        self.homepageURL = dto.homepageURL
    }
}

nonisolated
enum ProgramTargetAge: Equatable {
    case infant
    case child
    case youth
    case adult
    case senior
    case all
    
    init(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch value {
        case "유아":
            self = .infant
        case "어린이", "초등학생":
            self = .child
        case "청소년", "중학생", "고등학생":
            self = .youth
        case "성인", "일반":
            self = .adult
        case "노인", "어르신", "시니어":
            self = .senior
        default:
            self = .all
        }
    }
}

nonisolated
enum PriceUnit: Equatable {
    case day
    case month
    case session
    
    init(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch value {
        case "day":
            self = .day
        case "month":
            self = .month
        case "session":
            self = .session
        default:
            self = .month
        }
    }
}

nonisolated
enum ProgramLevel: Equatable {
    case beginner
    case intermediate
    case advanced
    case all
    
    init(_ rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch value {
        case "초급", "입문", "초보":
            self = .beginner
        case "중급":
            self = .intermediate
        case "고급", "상급":
            self = .advanced
        default:
            self = .all
        }
    }
}
