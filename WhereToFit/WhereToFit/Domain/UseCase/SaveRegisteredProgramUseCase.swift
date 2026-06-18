//
//  SaveRegisteredProgramUseCase.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

/*
 등록하기 버튼 탭
 -> ViewController가 Reactor에 Action 전달
 -> Reactor가 SaveRegisteredProgramUseCase.Input 생성
 -> saveRegisteredProgramUseCase.execute(input) 호출
 -> Repository가 CoreData에 저장
*/

final class SaveRegisteredProgramUseCase {
    // 프로그램 등록 화면에서 받은 입력값을 UseCase로 넘기기 위한 형태
    // 화면 입력값을 그대로 받고 저장 전에 필요한 정리는 하단의 execute 메서드에서 처리합니다.
    struct Input {
        let userProfileID: UUID
        let programID: Int?
        let facilityID: String?
        let programName: String
        let facilityName: String?
        let sportsCategory: SportsCategory?
        let isRecurring: Bool
        let days: [String]
        let hasReservationDates: Bool
        let reservationDates: [Date]
        let startMinuteOfDay: Int?
        let endMinuteOfDay: Int?
        let reservationMethodRawValues: [String]
    }

    // UseCase는 저장 방식(CoreData 등)을 직접 알지 않고 Repository Protocol에만 의존
    private let repository: RegisteredProgramRepositoryProtocol
    // 예약 날짜를 하루 단위로 정규화할 때 사용하는 Calendar
    private let calendar: Calendar

    init(
        repository: RegisteredProgramRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    // 입력값을 앱 저장 규칙에 맞게 RegisteredProgram으로 변환한 뒤 Repository에 저장
    func execute(_ input: Input) -> Single<RegisteredProgram> {
        let now = Date()
        let program = RegisteredProgram(
            id: UUID(),
            userProfileID: input.userProfileID,
            programID: input.programID,
            facilityID: input.facilityID,
            programName: input.programName,
            facilityName: input.facilityName,
            sportsCategory: input.sportsCategory,
            isRecurring: input.isRecurring,
            // 반복이 꺼져 있으면 이전에 선택했던 요일이 남지 않도록 비우기
            days: input.isRecurring ? input.days : [],
            hasReservationDates: input.hasReservationDates,
            // 예약 날짜가 꺼져 있으면 이전에 선택했던 날짜가 남지 않도록 비우기
            reservationDates: input.hasReservationDates ? normalizedDates(input.reservationDates) : [],
            startMinuteOfDay: input.startMinuteOfDay,
            endMinuteOfDay: input.endMinuteOfDay,
            reservationMethodRawValues: input.reservationMethodRawValues,
            createdAt: now,
            updatedAt: now
        )

        return repository.saveRegisteredProgram(program)
    }

    // Date는 시/분/초를 포함하므로 같은 날짜라도 서로 다른 값일 수 있습니다.
    // 저장 전 자정 기준으로 맞추고, 중복 날짜를 제거한 뒤 오래된 날짜부터 정렬합니다.
    private func normalizedDates(_ dates: [Date]) -> [Date] {
        Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
    }
}
