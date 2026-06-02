//
//  ClassInformationDTO.swift
//  WhereToFit
//
//  Created by 변예린 on 6/1/26.
//

import Foundation

struct ClassInformationDTO: Decodable {
    let id: Int? // Supabase class_information 테이블의 기본 키
    let facilityName: String? // 시설명
    let facilityLocation: String? // 시설소재지
    
    let className: String? // 강좌명
    let sport: String? // 종목
    let classDescription: String? // 강좌설명
    
    let targetAges: [String]? // 대상연령
    let levels: [String]? // 운동수준
    
    let isDisabledAccessible: Bool? // 장애인 가능 여부
    
    let price: String? // 강좌금액 원문
    let priceAmount: Int? // 정규화된 금액
    let priceUnit: String? // 금액 단위
    let priceNote: String? // 금액 부가 설명
    
    let days: [String]? // 강좌요일
    let startTime: String? // 강좌 시작 시간
    let endTime: String? // 강좌 종료 시간
    
    let phoneNumber: String? // 문의 전화번호
    let reservationMethods: [String]? // 예약 방법
    let homepageURL: String? // 홈페이지 주소
    
    let dataReferenceDate: String? // 데이터 기준일자
    let sourceDatasetName: String? // 원본 데이터셋명
    let sourceURL: String? // 원본 URL
    let sourceRowNumber: Int? // 원본 행 번호
    let createdAt: String? // Supabase 적재 시각

    enum CodingKeys: String, CodingKey {
        case id
        case facilityName = "facility_name"
        case facilityLocation = "facility_location"
        
        case className = "class_name"
        case sport
        case classDescription = "class_description"
        
        case targetAges = "target_ages"
        case levels = "skill_levels"
        
        case isDisabledAccessible = "is_disabled_accessible"
        
        case price
        case priceAmount = "price_amount"
        case priceUnit = "price_unit"
        case priceNote = "price_note"
        
        case days
        case startTime = "start_time"
        case endTime = "end_time"
        
        case phoneNumber = "phone_number"
        case reservationMethods = "reservation_methods"
        case homepageURL = "homepage_url"
        
        case dataReferenceDate = "data_reference_date"
        case sourceDatasetName = "source_dataset_name"
        case sourceURL = "source_url"
        case sourceRowNumber = "source_row_number"
        case createdAt = "created_at"
    }
}
