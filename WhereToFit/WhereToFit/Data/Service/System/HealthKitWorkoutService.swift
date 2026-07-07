//
//  HealthKitWorkoutService.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import HealthKit
import RxSwift

nonisolated struct HealthKitWorkoutSample: Equatable, Sendable {
    let uuid: UUID
    let activityTypeRawValue: Int
    let duration: TimeInterval
    let calories: Double?
    let startDate: Date
    let endDate: Date
}

protocol HealthKitWorkoutServiceProtocol {
    var isHealthDataAvailable: Bool { get }

    func requestAuthorization() -> Single<Bool>
    func fetchWorkouts(from startDate: Date, to endDate: Date) -> Single<[HealthKitWorkoutSample]>
}

final class HealthKitWorkoutService: HealthKitWorkoutServiceProtocol {
    private let healthStore: HKHealthStore

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestAuthorization() -> Single<Bool> {
        Single.create { [healthStore] single in
            guard HKHealthStore.isHealthDataAvailable() else {
                single(.success(false))
                return Disposables.create()
            }

            healthStore.requestAuthorization(
                toShare: [],
                read: [HKObjectType.workoutType()]
            ) { success, error in
                if let error {
                    single(.failure(error))
                    return
                }

                single(.success(success))
            }

            return Disposables.create()
        }
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) -> Single<[HealthKitWorkoutSample]> {
        Single.create { [healthStore] single in
            guard HKHealthStore.isHealthDataAvailable() else {
                single(.success([]))
                return Disposables.create()
            }

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: [.strictStartDate]
            )
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    single(.failure(error))
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? [])
                    .map(Self.makeWorkoutSample)
                single(.success(workouts))
            }

            healthStore.execute(query)

            return Disposables.create {
                healthStore.stop(query)
            }
        }
    }
}

private extension HealthKitWorkoutService {
    nonisolated static func makeWorkoutSample(from workout: HKWorkout) -> HealthKitWorkoutSample {
        HealthKitWorkoutSample(
            uuid: workout.uuid,
            activityTypeRawValue: Int(workout.workoutActivityType.rawValue),
            duration: workout.duration,
            calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            startDate: workout.startDate,
            endDate: workout.endDate
        )
    }
}
