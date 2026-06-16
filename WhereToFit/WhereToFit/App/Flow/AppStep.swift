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

    // Tab
    case homeTab
    case mapTab
    case calendarTab
    case myTab

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
    case pageBack
    
    // Home
    case locationSetting
}
