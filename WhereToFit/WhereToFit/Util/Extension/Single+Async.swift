//
//  Single+Async.swift
//  WhereToFit
//
//  Created by 변예린 on 6/2/26.
//

import RxSwift

extension Single {
    static func async(_ operation: @escaping () async throws -> Element) -> Single<Element> {
        Single.create { single in
            let task = Task {
                do {
                    single(.success(try await operation()))
                } catch {
                    single(.failure(error))
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
