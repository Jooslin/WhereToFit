//
//  AppStep.swift
//  Gymap
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

    // Tab
    case homeTab
    case mapTab
    case calendarTab
    case myTab
    
    // Map
    case mapFilter(FacilityFilter)
    case mapFacilityDetail(FitnessFacility)

    // My
    case profileManagement
    case notificationSetting
    case favoritePrograms
    case registeredPrograms
    case exerciseResult
    case pageBack
    
    // Home
    case locationSetting
}
