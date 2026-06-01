//
//  PublicFacilityDTO.swift
//  WhereToFit
//
//  Created by 변예린 on 6/1/26.
//

import Foundation
import FirebaseFirestore

struct PublicFacilityDTO: Decodable {
    @DocumentID var id: String? // 파이어베이스에서 데이터가 담겨있는 문서의 ID
    let facilityName: String? // 개방시설 이름
    let locationName: String? // 개방장소 이름
    let facilityType: String? // 개방시설 유형
    
    let closeDays: String? // 휴관일
    let weekdayOpenTime: String? // 평일 운영 시작 시각
    let weekdayCloseTime: String? // 평일 운영 종료 시각
    let weekendOpenTime: String? // 주말 운영 시작 시각
    let weekendCloseTime: String? // 주말 운영 종료 시각
    
    let isPaid: String? // 유료 사용 여부
    let usageStandardTime: String? // 사용 기준 시간 (사용 단위 시간)
    let rentalFee: String? // 사용료
    let excessUseUnitTime: String? // 초과 사용 단위 시간
    let excessRentalFee: String? // 초과사용료
    
    let capacity: Double? // 수용가능 인원 수
    let area: Double? // 면적
    let extraFacilityInfo: String? // 부대시설 정보
    
    let applicationMethodType: String? // 신청 방법 구분
    let facilityImage: String? // 시설 이미지 정보
    
    let roadAddress: String? // 소재지 도로명주소
    let lotNumberAddress: String? // 소재지 지번주소
    let latitude: Double? // 위도
    let longitude: Double? // 경도
    
    let institution: String? // 관리기관 이름
    let chargeDepartment: String? // 담당 부서
    let phoneNumber: String? // 문의 전화번호
    let homepageUrl: String? // 홈페이지 주소
    let referenceDate: String? // 데이터 기준일자
    let institutionCode: String? // 관리기관코드
    let providerInstitution: String? // 제공기관 이름

    enum CodingKeys: String, CodingKey {
        case facilityName = "openFcltyNm"
        case locationName = "openLcNm"
        case facilityType = "openFcltyType"
        
        case closeDays = "rstde"
        case weekdayOpenTime = "weekdayOperOpenHhmm"
        case weekdayCloseTime = "weekdayOperColseHhmm"
        case weekendOpenTime = "wkendOperOpenHhmm"
        case weekendCloseTime = "wkendOperCloseHhmm"
        
        case isPaid = "pchrgUseYn"
        case usageStandardTime = "useStdrTime"
        case rentalFee = "rntfee"
        case excessUseUnitTime
        case excessRentalFee = "excessRntfee"
        
        case capacity = "aceptncPosblCo"
        case area = "ar"
        case extraFacilityInfo = "etcFclty"
        
        case applicationMethodType = "sbscrptnMthSe"
        case facilityImage = "fcltyPicInfo"
        
        case roadAddress = "rdnmadr"
        case lotNumberAddress = "lnmadr"
        case latitude
        case longitude
        
        case institution = "institutionNm"
        case chargeDepartment = "chrgDeptNm"
        case phoneNumber
        case homepageUrl
        case referenceDate
        case institutionCode = "insttCode"
        case providerInstitution = "insttNm"
    }
}
