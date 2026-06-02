//
//  Facility.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import Foundation

struct Facility {
    let id: String?
    let facilityName: String?
    let locationName: String?
    let facilityType: FacilityType
    
    let closeDays: String?
    let weekdayOpenTime: String?
    let weekdayCloseTime: String?
    let weekendOpenTime: String?
    let weekendCloseTime: String?
    
    let isPaid: String?
    let usageStandardTime: String?
    let rentalFee: String?
    let excessUseUnitTime: String?
    let excessRentalFee: String?
    
    let capacity: Double?
    let area: Double?
    let extraFacilityInfo: String?
    
    let applicationMethodType: String?
    let facilityImage: String?
    
    let roadAddress: String?
    let lotNumberAddress: String?
    let latitude: Double?
    let longitude: Double?
    
    let institution: String?
    let chargeDepartment: String?
    let phoneNumber: String?
    let homepageUrl: String?
    let referenceDate: String?
    let institutionCode: String?
    let providerInstitution: String?
}

extension Facility {
    init(dto: PublicFacilityDTO) {
        self.id = dto.id
        self.facilityName = dto.facilityName
        self.locationName = dto.locationName
        self.facilityType = FacilityType(dto.facilityType)
        self.closeDays = dto.closeDays
        self.weekdayOpenTime = dto.weekdayOpenTime
        self.weekdayCloseTime = dto.weekdayCloseTime
        self.weekendOpenTime = dto.weekendOpenTime
        self.weekendCloseTime = dto.weekendCloseTime
        self.isPaid = dto.isPaid
        self.usageStandardTime = dto.usageStandardTime
        self.rentalFee = dto.rentalFee
        self.excessUseUnitTime = dto.excessUseUnitTime
        self.excessRentalFee = dto.excessRentalFee
        self.capacity = dto.capacity
        self.area = dto.area
        self.extraFacilityInfo = dto.extraFacilityInfo
        self.applicationMethodType = dto.applicationMethodType
        self.facilityImage = dto.facilityImage
        self.roadAddress = dto.roadAddress
        self.lotNumberAddress = dto.lotNumberAddress
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.institution = dto.institution
        self.chargeDepartment = dto.chargeDepartment
        self.phoneNumber = dto.phoneNumber
        self.homepageUrl = dto.homepageUrl
        self.referenceDate = dto.referenceDate
        self.institutionCode = dto.institutionCode
        self.providerInstitution = dto.providerInstitution
    }
}

enum FacilityType: Equatable {
    case auditorium
    case classroom
    case conferenceRoom
    case gym
    case sportsFacility
    case parkingLot
    case other(String)
    case unknown
    
    init(_ rawValue: String?) {
        let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        switch value {
        case "강당":
            self = .auditorium
        case "강의실":
            self = .classroom
        case "회의실":
            self = .conferenceRoom
        case "체육관":
            self = .gym
        case "체육시설":
            self = .sportsFacility
        case "주차장":
            self = .parkingLot
        case "":
            self = .unknown
        default:
            self = .other(value)
        }
    }
}
