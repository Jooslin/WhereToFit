//
//  FetchICloudSyncStatusUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import Foundation
import RxSwift

final class FetchICloudSyncStatusUseCase {
    private let service: ICloudStatusServiceProtocol

    init(service: ICloudStatusServiceProtocol) {
        self.service = service
    }

    func execute() -> Single<ICloudSyncStatus> {
        service.fetchStatus()
    }
}
