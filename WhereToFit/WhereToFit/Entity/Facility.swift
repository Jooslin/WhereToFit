//
//  Facility.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import Foundation

struct Facility {
    let id: String?
    let facilityName: String? // 시설 이름
    let locationName: String? // 장소 이름 - ex. 증산동 자치회관
    let facilityType: String? // 시설 타입 - ex. 다목적실
    
    let closeDays: String? // 휴관일
    let weekdayOpenTime: String? // 평일 운영 시작 시각
    let weekdayCloseTime: String? // 평일 운영 종료 시각
    let weekendOpenTime: String? // 주말 운영 시작 시각
    let weekendCloseTime: String? // 주말 운영 종료 시각
    
    let isPaid: Bool // 유료 사용 여부
    let usageStandardTime: String? // 사용 기준 시간 단위
    let rentalFee: String? // 사용료
    let excessUseUnitTime: String? // 초과 시간 단위
    let excessRentalFee: String? // 초과 사용료
    
    let capacity: String? // 수용 가능 인원수
    let area: String? // 면적
    let extraFacilityInfo: String? // 부대시설
    
    let reservationMethods: [ReservationMethod] // 예약 방법
    let facilityImage: String? // 시설 이미지
    
    let roadAddress: String? // 도로명주소
    let lotNumberAddress: String? // 지번주소
    let latitude: Double? // 위도
    let longitude: Double? // 경도
    
    let institution: String? // 관리기관
    let chargeDepartment: String? // 담당 부서
    let phoneNumber: String? // 전화번호
    let homepageUrl: String? // 홈페이지 주소
}

extension Facility {
    init(dto: PublicFacilityDTO) {
        self.id = dto.id
        self.facilityName = dto.facilityName
        self.locationName = dto.locationName
        self.facilityType = dto.facilityType
        
        self.closeDays = dto.closeDays
        self.weekdayOpenTime = dto.weekdayOpenTime
        self.weekdayCloseTime = dto.weekdayCloseTime
        self.weekendOpenTime = dto.weekendOpenTime
        self.weekendCloseTime = dto.weekendCloseTime
        
        self.isPaid = Facility.parseIsPaid(dto.isPaid)
        self.usageStandardTime = dto.usageStandardTime
        self.rentalFee = dto.rentalFee
        self.excessUseUnitTime = dto.excessUseUnitTime
        self.excessRentalFee = dto.excessRentalFee
        
        self.capacity = dto.capacity
        self.area = dto.area
        self.extraFacilityInfo = dto.extraFacilityInfo
        
        self.reservationMethods = ReservationMethod.parse(dto.applicationMethodType)
        self.facilityImage = dto.facilityImage
        self.roadAddress = dto.roadAddress
        self.lotNumberAddress = dto.lotNumberAddress
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        
        self.institution = dto.institution
        self.chargeDepartment = dto.chargeDepartment
        self.phoneNumber = dto.phoneNumber
        self.homepageUrl = dto.homepageUrl
    }
}

private extension Facility {
    static func parseIsPaid(_ rawValue: String?) -> Bool {
        let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        switch value {
        case "Y", "y", "유료", "true", "TRUE", "1":
            return true
        default:
            return false
        }
    }
}
