//
//  UserProgram.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation

nonisolated struct RegisteredProgram: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let programID: Int? // 프로그램 아이디
    let facilityID: String? // 시설 아이디
    
    let programName: String // 프로그램 이름
    let facilityName: String? // 시설 이름
    let sportsCategory: SportsCategory? // 카테고리
    
    let isRecurring: Bool // 반복 요일 여부
    let days: [String] // 반복 요일
    
    let hasReservationDates: Bool // 예약 날짜 여부
    let reservationDates: [Date] // 저장 날짜
    
    let startMinuteOfDay: Int? // 시작 시간(계산 쉽게 인트로 저장)
    let endMinuteOfDay: Int? // 끝나는 시간
    // 예시 10:00 AM = 10 * 60 + 0 = 600
    // 1:30 PM = 13 * 60 + 30 = 810
    
    let reservationMethodRawValues: [String] // 예약 딱지용..?
    let createdAt: Date // 만들어진 날짜
    let updatedAt: Date // 업데이트 날짜
}

nonisolated struct Favorite: Equatable, Sendable {
    let id: UUID
    let userProfileID: UUID
    let targetType: FavoriteTargetType
    let targetID: String
    let title: String
    let subtitle: String?
    let sportsCategoryRawValue: String?
    let snapshotJSON: String?
    let createdAt: Date
    let updatedAt: Date
}

nonisolated enum FavoriteTargetType: String, Equatable, Sendable {
    case facility
    case program
}
