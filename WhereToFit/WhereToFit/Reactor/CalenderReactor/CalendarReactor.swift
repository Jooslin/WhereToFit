//
//  CalendarReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import Foundation
import ReactorKit
import RxSwift

final class CalendarReactor: BaseReactor {
    let initialState: State
    private let saveWeightRecordUseCase: SaveWeightRecordUseCase
    private let saveConditionRecordUseCase: SaveConditionRecordUseCase
    private let fetchCalendarDayRecordsUseCase: FetchCalendarDayRecordsUseCase

    init(
        saveWeightRecordUseCase: SaveWeightRecordUseCase,
        saveConditionRecordUseCase: SaveConditionRecordUseCase,
        fetchCalendarDayRecordsUseCase: FetchCalendarDayRecordsUseCase
    ) {
        self.saveWeightRecordUseCase = saveWeightRecordUseCase
        self.saveConditionRecordUseCase = saveConditionRecordUseCase
        self.fetchCalendarDayRecordsUseCase = fetchCalendarDayRecordsUseCase
        initialState = State(
            selectedDate: Self.normalizedDate(Date()),
            weight: nil,
            condition: nil,
            exerciseItems: []
        )
    }

    struct WeightValue: Equatable {
        let integer: Int
        let decimal: Int

        var displayText: String {
            "\(integer).\(decimal)"
        }

        var doubleValue: Double {
            Double(integer) + Double(decimal) / 10
        }
    }

    enum ConditionValue: CaseIterable, Equatable {
        case veryGood
        case good
        case normal
        case bad
        case worst

        var displayText: String {
            switch self {
            case .veryGood:
                return "매우 좋음"
            case .good:
                return "좋음"
            case .normal:
                return "보통"
            case .bad:
                return "안좋음"
            case .worst:
                return "최악"
            }
        }

        var conditionLevel: ConditionLevel {
            switch self {
            case .veryGood:
                return .veryGood
            case .good:
                return .good
            case .normal:
                return .normal
            case .bad:
                return .bad
            case .worst:
                return .worst
            }
        }
    }

    struct ExerciseItem: Equatable {
        let title: String
        let duration: String
        let calories: String
        let sportsCategoryRawValue: String?
    }

    enum Action {
        case viewDidLoad
        case selectDate(Date)
        case moveToToday
        case refreshSelectedDate
        case updateWeight(WeightValue)
        case updateCondition(ConditionValue)
    }

    enum Mutation {
        case setSelectedDate(Date)
        case setWeight(WeightValue)
        case setCondition(ConditionValue)
        case setCalendarDayRecords(CalendarDayRecords)
        case setError(String, String)
    }

    struct State {
        var selectedDate: Date
        var weight: WeightValue?
        var condition: ConditionValue?
        var exerciseItems: [ExerciseItem]
        @Pulse var error: (String, String)?
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchCalendarDayRecords(date: currentState.selectedDate)

        case .selectDate(let date):
            let selectedDate = Self.normalizedDate(date)
            return .concat([
                .just(.setSelectedDate(selectedDate)),
                fetchCalendarDayRecords(date: selectedDate)
            ])

        case .moveToToday:
            let selectedDate = Self.normalizedDate(Date())
            return .concat([
                .just(.setSelectedDate(selectedDate)),
                fetchCalendarDayRecords(date: selectedDate)
            ])

        case .refreshSelectedDate:
            return fetchCalendarDayRecords(date: currentState.selectedDate)

        case .updateWeight(let weight):
            return saveWeightRecordUseCase.execute(
                date: currentState.selectedDate,
                value: weight.doubleValue
            )
            .asObservable()
            .flatMap { [weak self] _ -> Observable<Mutation> in
                guard let self else { return .empty() }
                return self.fetchCalendarDayRecords(date: self.currentState.selectedDate)
            }
            .catch { _ in
                .just(.setError("저장 실패", "몸무게 기록을 저장할 수 없습니다.\n잠시 후 다시 시도해주세요."))
            }

        case .updateCondition(let condition):
            return saveConditionRecordUseCase.execute(
                date: currentState.selectedDate,
                condition: condition.conditionLevel
            )
            .asObservable()
            .flatMap { [weak self] _ -> Observable<Mutation> in
                guard let self else { return .empty() }
                return self.fetchCalendarDayRecords(date: self.currentState.selectedDate)
            }
            .catch { _ in
                .just(.setError("저장 실패", "컨디션 기록을 저장할 수 없습니다.\n잠시 후 다시 시도해주세요."))
            }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSelectedDate(let date):
            newState.selectedDate = date
        case .setWeight(let weight):
            newState.weight = weight
        case .setCondition(let condition):
            newState.condition = condition
        case .setCalendarDayRecords(let records):
            newState.weight = Self.makeWeightValue(from: records.weightRecord)
            newState.condition = Self.makeConditionValue(from: records.conditionRecord)
            newState.exerciseItems = records.exerciseRecords.map(Self.makeExerciseItem)
        case .setError(let title, let message):
            newState.error = (title, message)
        }

        return newState
    }

    private static func normalizedDate(_ date: Date) -> Date {
        Calendar(identifier: .gregorian).startOfDay(for: date)
    }

    private func fetchCalendarDayRecords(date: Date) -> Observable<Mutation> {
        fetchCalendarDayRecordsUseCase.execute(date: date)
            .asObservable()
            .map(Mutation.setCalendarDayRecords)
            .catch { _ in
                .just(.setError("기록 조회 실패", "선택한 날짜의 기록을 불러올 수 없습니다.\n잠시 후 다시 시도해주세요."))
            }
    }

    nonisolated private static func makeWeightValue(from record: WeightRecord?) -> WeightValue? {
        guard let record else { return nil }

        let tenths = Int((record.value * 10).rounded())
        return WeightValue(integer: tenths / 10, decimal: abs(tenths % 10))
    }

    nonisolated private static func makeConditionValue(from record: ConditionRecord?) -> ConditionValue? {
        guard let condition = record?.condition else { return nil }

        switch condition {
        case .veryGood:
            return .veryGood
        case .good:
            return .good
        case .normal:
            return .normal
        case .bad:
            return .bad
        case .worst:
            return .worst
        }
    }

    nonisolated private static func makeExerciseItem(from record: ExerciseRecord) -> ExerciseItem {
        ExerciseItem(
            title: record.exerciseName,
            duration: makeDurationText(record.duration),
            calories: "\(Int(record.calories ?? 0))칼로리",
            sportsCategoryRawValue: record.sportsCategoryRawValue
        )
    }

    nonisolated private static func makeDurationText(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        if hours > 0 {
            return "\(hours)시간"
        }

        return "\(minutes)분"
    }
}
