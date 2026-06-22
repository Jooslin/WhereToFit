//
//  ICloudSyncStatus.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation

nonisolated enum ICloudSyncStatus: Equatable, Sendable {
    case available
    case needsAttention
}
