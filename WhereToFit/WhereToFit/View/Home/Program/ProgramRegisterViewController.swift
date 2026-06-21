//
//  ProgramRegisterViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/17/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa
import SnapKit
import Then

final class ProgramRegisterViewController: BaseViewController<ProgramRegisterReactor> {
    private let registerView = ProgramRegisterView()
    
    override func loadView() {
        view = registerView
    }
    
    override func viewWillAppear(_ animate: Bool) {
        super.viewWillAppear(animate)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func bind(reactor: ProgramRegisterReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: ProgramRegisterReactor) {
        // TitleView
        registerView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        // button
        registerView.facilityTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.facilitySearch }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        registerView.sportsTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.sportsCategorySelection }
            .bind(to: steps)
            .disposed(by: disposeBag)

        registerView.programTextField.rx.controlEvent(.editingChanged)
            .withLatestFrom(registerView.programTextField.rx.text.orEmpty)
            .map(ProgramRegisterReactor.Action.updateProgramName)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        registerView.programTextField.rx.controlEvent(.editingDidEnd)
            .map { ProgramRegisterReactor.Action.finishProgramDirectInput }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        registerView.dateTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.selectDate }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        registerView.regularButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { ProgramRegisterReactor.Action.toggleRecurring }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        registerView.reservationButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { ProgramRegisterReactor.Action.toggleReservationDates }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        registerView.rx.weekdayButtonSelected
            .compactMap(Weekday.init(rawValue:))
            .map(ProgramRegisterReactor.Action.toggleWeekday)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        registerView.startTimeTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withLatestFrom(reactor.state.map(\.startMinuteOfDay))
            .bind(with: self) { owner, selectedMinute in
                owner.presentTimePicker(
                    title: "시작 시간",
                    selectedMinuteOfDay: selectedMinute
                ) { minuteOfDay in
                    reactor.action.onNext(.selectStartTime(minuteOfDay))
                }
            }
            .disposed(by: disposeBag)

        registerView.endTimeTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withLatestFrom(
                reactor.state.map {
                    EndTimePickerState(
                        startMinuteOfDay: $0.startMinuteOfDay,
                        endMinuteOfDay: $0.endMinuteOfDay
                    )
                }
            )
            .bind(with: self) { owner, state in
                owner.presentTimePicker(
                    title: "끝나는 시간",
                    selectedMinuteOfDay: Self.makeInitialMinuteOfDay(
                        selectedMinuteOfDay: state.endMinuteOfDay,
                        minimumMinuteOfDay: state.startMinuteOfDay
                    ),
                    minimumMinuteOfDay: state.startMinuteOfDay
                ) { minuteOfDay in
                    reactor.action.onNext(.selectEndTime(minuteOfDay))
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: ProgramRegisterReactor) {
        reactor.state
            .map(\.facilityName)
            .distinctUntilChanged()
            .bind(to: registerView.facilityTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state
            .map(\.sportsCategoryDisplayName)
            .distinctUntilChanged()
            .bind(to: registerView.sportsTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.programOptions)
            .distinctUntilChanged()
            .bind(with: self) { owner, options in
                owner.updateProgramMenu(options: options)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.programName)
            .distinctUntilChanged()
            .bind(with: self) { owner, programName in
                guard owner.registerView.programTextField.isFirstResponder == false else {
                    return
                }

                owner.registerView.programTextField.text = programName
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isProgramDirectInputEnabled)
            .distinctUntilChanged()
            .bind(with: self) { owner, isEnabled in
                owner.registerView.programMenuButton.isHidden = isEnabled

                if isEnabled {
                    owner.registerView.programTextField.becomeFirstResponder()
                }
            }
            .disposed(by: disposeBag)

        reactor.state
            .map {
                ScheduleInputVisibilityState(
                    isRecurring: $0.isRecurring,
                    hasReservationDates: $0.hasReservationDates
                )
            }
            .distinctUntilChanged()
            .bind(with: self) { owner, state in
                owner.registerView.regularButton.isSelected = state.isRecurring
                owner.registerView.reservationButton.isSelected = state.hasReservationDates
                owner.registerView.updateScheduleInputVisibility()
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedWeekdays)
            .distinctUntilChanged()
            .bind(with: self) { owner, weekdays in
                owner.updateWeekdayButtons(selectedWeekdays: weekdays)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.dates)
            .distinctUntilChanged()
            .map(Self.makeDateText)
            .bind(to: registerView.dateTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.startMinuteOfDay)
            .distinctUntilChanged()
            .map(Self.makeTimeText)
            .bind(to: registerView.startTimeTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.endMinuteOfDay)
            .distinctUntilChanged()
            .map(Self.makeTimeText)
            .bind(to: registerView.endTimeTextField.rx.text)
            .disposed(by: disposeBag)
    }
}

private extension ProgramRegisterViewController {
    func updateProgramMenu(options: [ProgramRegisterReactor.ProgramOption]) {
        var actions = options.map { option in
            UIAction(title: option.name) { [weak self] _ in
                self?.reactor?.action.onNext(.selectProgram(option))
            }
        }

        actions.append(
            UIAction(title: "직접 입력") { [weak self] _ in
                self?.reactor?.action.onNext(.selectDirectProgramInput)
            }
        )

        registerView.programMenuButton.menu = UIMenu(children: actions)
    }

    func updateWeekdayButtons(selectedWeekdays: Set<Weekday>) {
        registerView.weekdayButtons.arrangedSubviews
            .compactMap { $0 as? DesignButton }
            .forEach { button in
                guard let weekday = Weekday(rawValue: button.tag) else { return }
                button.isSelected = selectedWeekdays.contains(weekday)
            }
    }

    func presentTimePicker(
        title: String,
        selectedMinuteOfDay: Int?,
        minimumMinuteOfDay: Int? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        let pickerViewController = UIViewController()
        pickerViewController.view.backgroundColor = .white

        let titleLabel = UILabel(text: title, config: .title16, color: .gray900)
        let datePicker = UIDatePicker().then {
            $0.datePickerMode = .time
            $0.preferredDatePickerStyle = .wheels
            $0.locale = Locale(identifier: "ko_KR")
            $0.date = Self.makeDate(minuteOfDay: selectedMinuteOfDay)
            $0.minimumDate = minimumMinuteOfDay.map(Self.makeDate)
        }
        let applyButton = DesignButton(config: .largeFilledBlue).then {
            $0.title = "적용"
        }

        let stackView = UIStackView(arrangedSubviews: [titleLabel, datePicker, applyButton]).then {
            $0.axis = .vertical
            $0.spacing = 12
            $0.alignment = .fill
        }

        pickerViewController.view.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalTo(pickerViewController.view.safeAreaLayoutGuide).inset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
        }

        applyButton.addAction(UIAction { [weak pickerViewController] _ in
            onSelect(Self.makeMinuteOfDay(from: datePicker.date))
            pickerViewController?.dismiss(animated: true)
        }, for: .touchUpInside)

        pickerViewController.modalPresentationStyle = .pageSheet
        if let sheet = pickerViewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(pickerViewController, animated: true)
    }

    nonisolated static func makeDateText(_ dates: [Date]) -> String? {
        let sortedDates = dates.sorted()
        guard sortedDates.isEmpty == false else {
            return nil
        }

        let fullFormatter = DateFormatter()
        fullFormatter.locale = Locale(identifier: "ko_KR")
        fullFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        fullFormatter.dateFormat = "yyyy.MM.dd"

        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "ko_KR")
        shortFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        shortFormatter.dateFormat = "MM.dd"

        let displayDates = sortedDates.prefix(3).enumerated().map { index, date in
            index == 0 ? fullFormatter.string(from: date) : shortFormatter.string(from: date)
        }

        let dateText = displayDates.joined(separator: " , ")
        let hiddenDateCount = sortedDates.count - displayDates.count

        if hiddenDateCount > 0 {
            return "\(dateText) 외 \(hiddenDateCount)개"
        }

        return dateText
    }

    nonisolated static func makeTimeText(_ minuteOfDay: Int?) -> String? {
        guard let minuteOfDay else {
            return nil
        }

        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    nonisolated static func makeDate(minuteOfDay: Int?) -> Date {
        let minuteOfDay = minuteOfDay ?? 540
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = minuteOfDay / 60
        components.minute = minuteOfDay % 60

        return calendar.date(from: components) ?? Date()
    }

    nonisolated static func makeMinuteOfDay(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        return hour * 60 + minute
    }

    nonisolated static func makeInitialMinuteOfDay(
        selectedMinuteOfDay: Int?,
        minimumMinuteOfDay: Int?
    ) -> Int? {
        guard let minimumMinuteOfDay else {
            return selectedMinuteOfDay
        }

        guard let selectedMinuteOfDay else {
            return minimumMinuteOfDay
        }

        return max(selectedMinuteOfDay, minimumMinuteOfDay)
    }
}

private struct ScheduleInputVisibilityState: Equatable {
    let isRecurring: Bool
    let hasReservationDates: Bool
}

private struct EndTimePickerState {
    let startMinuteOfDay: Int?
    let endMinuteOfDay: Int?
}
