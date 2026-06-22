//
//  ICloudStatusService.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import CloudKit
import Foundation
import RxSwift

protocol ICloudStatusServiceProtocol {
    func fetchStatus() -> Single<ICloudSyncStatus>
}

final class ICloudStatusService: ICloudStatusServiceProtocol {
    func fetchStatus() -> Single<ICloudSyncStatus> {
        Single.create { single in
            CKContainer.default().accountStatus { status, _ in
                let syncStatus: ICloudSyncStatus = status == .available ? .available : .needsAttention
                single(.success(syncStatus))
            }

            return Disposables.create()
        }
    }
}
