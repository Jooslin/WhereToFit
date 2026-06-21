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
    private let fetchReportRecordsUseCase: FetchReportRecordsUseCase

    init(
        saveWeightRecordUseCase: SaveWeightRecordUseCase,
        saveConditionRecordUseCase: SaveConditionRecordUseCase,
        fetchCalendarDayRecordsUseCase: FetchCalendarDayRecordsUseCase,
        fetchReportRecordsUseCase: FetchReportRecordsUseCase
    ) {
        self.saveWeightRecordUseCase = saveWeightRecordUseCase
        self.saveConditionRecordUseCase = saveConditionRecordUseCase
        self.fetchCalendarDayRecordsUseCase = fetchCalendarDayRecordsUseCase
        self.fetchReportRecordsUseCase = fetchReportRecordsUseCase
        initialState = State(
            selectedDate: Self.normalizedDate(Date()),
            weight: nil,
            condition: nil,
            exerciseItems: [],
            report: .empty
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

    struct ReportState: Equatable {
        let isEmpty: Bool
        let weight: WeightReportState
        let exercise: ExerciseReportState
        let condition: ConditionReportState

        static let empty = ReportState(
            isEmpty: true,
            weight: .empty,
            exercise: .empty,
            condition: .empty
        )
    }

    struct WeightReportState: Equatable {
        let changeText: String
        let values: [Double]
        let yLabels: [String]
        let startLabel: String
        let endLabel: String
        let selectedValueText: String?
        let emptyMessage: String?

        static let empty = WeightReportState(
            changeText: "-",
            values: [],
            yLabels: [],
            startLabel: "",
            endLabel: "",
            selectedValueText: nil,
            emptyMessage: "몸무게 기록을 2개 이상 입력하면 변화 그래프를 볼 수 있어요"
        )
    }

    struct ExerciseReportState: Equatable {
        let totalMinutesText: String
        let dailyMinutes: [Double]
        let emptyMessage: String?

        static let empty = ExerciseReportState(
            totalMinutesText: "0",
            dailyMinutes: Array(repeating: 0, count: 7),
            emptyMessage: "운동 기록을 입력하면 주간 운동 현황을 볼 수 있어요"
        )
    }

    struct ConditionReportState: Equatable {
        let latestText: String
        let values: [Double]
        let startLabel: String
        let endLabel: String
        let conditionValues: [ConditionValue]
        let emptyMessage: String?

        static let empty = ConditionReportState(
            latestText: "-",
            values: [],
            startLabel: "",
            endLabel: "",
            conditionValues: [],
            emptyMessage: "컨디션 기록을 2개 이상 입력하면 변화 그래프를 볼 수 있어요"
        )
    }

    enum Action {
        case viewDidLoad
        case selectDate(Date)
        case moveToToday
        case refreshSelectedDate
        case reportTabSelected
        case updateWeight(WeightValue)
        case updateCondition(ConditionValue)
    }

    enum Mutation {
        case setSelectedDate(Date)
        case setWeight(WeightValue)
        case setCondition(ConditionValue)
        case setCalendarDayRecords(CalendarDayRecords)
        case setReport(ReportState)
        case setError(String, String)
    }

    struct State {
        var selectedDate: Date
        var weight: WeightValue?
        var condition: ConditionValue?
        var exerciseItems: [ExerciseItem]
        var report: ReportState
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

        case .reportTabSelected:
            return fetchReportRecords()

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
        case .setReport(let report):
            newState.report = report
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

    private func fetchReportRecords() -> Observable<Mutation> {
        fetchReportRecordsUseCase.execute()
            .asObservable()
            .map { records in
                .setReport(Self.makeReportState(from: records))
            }
            .catch { _ in
                .just(.setError("리포트 조회 실패", "리포트 기록을 불러올 수 없습니다.\n잠시 후 다시 시도해주세요."))
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

private extension CalendarReactor {
    static func makeReportState(from records: ReportRecords) -> ReportState {
        let weight = makeWeightReportState(from: records.weightRecords)
        let exercise = makeExerciseReportState(from: records.exerciseRecords)
        let condition = makeConditionReportState(from: records.conditionRecords)

        return ReportState(
            isEmpty: records.weightRecords.isEmpty
                && records.exerciseRecords.isEmpty
                && records.conditionRecords.isEmpty,
            weight: weight,
            exercise: exercise,
            condition: condition
        )
    }

    static func makeWeightReportState(from records: [WeightRecord]) -> WeightReportState {
        guard records.count > 1,
              let first = records.first,
              let last = records.last else {
            return .empty
        }

        let values = records.map(\.value)
        let minimum = floor((values.min() ?? 0) - 1)
        let maximum = ceil((values.max() ?? 0) + 1)
        let step = max((maximum - minimum) / 5, 1)
        let yLabels = stride(from: maximum, through: minimum, by: -step)
            .prefix(6)
            .map { "\(Int($0))kg" }
        let change = last.value - first.value
        let changeText = change > 0 ? "+\(formatDecimal(change))" : formatDecimal(change)

        return WeightReportState(
            changeText: changeText,
            values: values,
            yLabels: yLabels,
            startLabel: makeMonthDayText(first.date),
            endLabel: makeMonthDayText(last.date),
            selectedValueText: "\(formatDecimal(last.value))kg",
            emptyMessage: nil
        )
    }

    static func makeExerciseReportState(from records: [ExerciseRecord]) -> ExerciseReportState {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let dates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 6, to: today)
        }
        let minutesByDate = Dictionary(grouping: records, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { records in
                records.reduce(0.0) { $0 + $1.duration / 60 }
            }
        let dailyMinutes = dates.map { minutesByDate[$0] ?? 0 }
        let totalMinutes = Int(dailyMinutes.reduce(0, +).rounded())

        return ExerciseReportState(
            totalMinutesText: "\(totalMinutes)",
            dailyMinutes: dailyMinutes,
            emptyMessage: records.isEmpty ? ExerciseReportState.empty.emptyMessage : nil
        )
    }

    static func makeConditionReportState(from records: [ConditionRecord]) -> ConditionReportState {
        guard records.count > 1,
              let first = records.first,
              let last = records.last,
              let latestCondition = makeConditionValue(from: last) else {
            return .empty
        }

        let values = records.map { Double(conditionScore($0.condition)) }
        let conditionValues = records.compactMap(makeConditionValue)

        return ConditionReportState(
            latestText: latestCondition.displayText,
            values: values,
            startLabel: makeMonthDayText(first.date),
            endLabel: makeMonthDayText(last.date),
            conditionValues: conditionValues,
            emptyMessage: nil
        )
    }

    static func conditionScore(_ condition: ConditionLevel) -> Int {
        switch condition {
        case .worst:
            return 0
        case .bad:
            return 1
        case .normal:
            return 2
        case .good:
            return 3
        case .veryGood:
            return 4
        }
    }

    static func makeMonthDayText(_ date: Date) -> String {
        let components = Calendar(identifier: .gregorian).dateComponents([.month, .day], from: date)
        return "\(components.month ?? 0)/\(components.day ?? 0)"
    }

    static func formatDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }

        return String(format: "%.1f", rounded)
    }
}
