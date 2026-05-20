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
    case main
    case updateRequired(message: String, storeURL: URL)
}
