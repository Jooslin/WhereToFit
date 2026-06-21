//
//  AppStep.swift
//  WhereToFit
//
//  Created by 변예린 on 5/19/26.
//

import RxFlow
import Foundation

enum AppStep: Step {
    // Main
    case splash
    case onboarding
    case main
    case updateRequired(message: String, storeURL: URL)
    case alert(title: String, message: String)

    // Tab
    case homeTab
    case mapTab
    case calendarTab
    case myTab
    
    // Map
    case mapFilter(FacilityFilter, priceSamples: [Int] = [], mode: MapFilterMode = .all)
    case mapFacilityDetail(FitnessFacility, relatedPrograms: [FitnessFacility] = [])

    // Calendar
    case calendarWeightInput
    case calendarConditionInput
    case calendarExerciseRecordInput

    // My
    case profileManagement
    case notificationSetting
    case favoritePrograms
    case registeredPrograms
    case exerciseResult
    case exerciseResultRetry
    case pageBack
    
    // Home
    case locationSetting
    case locationEdit
    case locationDetail(LocationEditMode)
    case programRegistration
    case facilitySearch
    case selectDate
}
