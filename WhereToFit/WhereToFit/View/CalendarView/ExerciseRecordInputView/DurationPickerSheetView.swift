//
//  DurationPickerSheetView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class DurationPickerSheetView: UIView {
    let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .gray600
    }

    let selectButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "선택하기"
    }

    fileprivate let durationChangedRelay = PublishRelay<ExerciseRecordInputReactor.DurationValue>()
    private let pickerView = UIPickerView()
    private let hours = Array(0...12)
    private let minutes = Array(0...59)
    private let seconds = Array(0...59)
    private var selectedDuration = ExerciseRecordInputReactor.DurationValue(hour: 0, minute: 30, second: 0)

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }

    private let sheetView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let titleLabel = UILabel(text: "운동한 시간", config: .body14Medium, color: .gray700)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setLayout()
        setPicker()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DurationPickerSheetView {
    func updateSelectedDuration(_ duration: ExerciseRecordInputReactor.DurationValue) {
        let clampedDuration = clampedDuration(duration)
        selectedDuration = clampedDuration
        pickerView.selectRow(clampedDuration.hour, inComponent: 0, animated: false)
        pickerView.selectRow(clampedDuration.minute, inComponent: 1, animated: false)
        pickerView.selectRow(clampedDuration.second, inComponent: 2, animated: false)
    }
}

private extension DurationPickerSheetView {
    func clampedDuration(
        _ duration: ExerciseRecordInputReactor.DurationValue
    ) -> ExerciseRecordInputReactor.DurationValue {
        ExerciseRecordInputReactor.DurationValue(
            hour: duration.hour.clamped(to: hours),
            minute: duration.minute.clamped(to: minutes),
            second: duration.second.clamped(to: seconds)
        )
    }

    func setStyle() {
        backgroundColor = .clear
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            titleLabel,
            closeButton,
            pickerView,
            selectButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(40)
            $0.leading.equalToSuperview().offset(16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        pickerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(22)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.height.equalTo(168)
        }

        selectButton.snp.makeConstraints {
            $0.top.equalTo(pickerView.snp.bottom).offset(32)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(16).priority(999)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setPicker() {
        pickerView.dataSource = self
        pickerView.delegate = self
        updateSelectedDuration(selectedDuration)
    }
}

extension DurationPickerSheetView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return hours.count
        case 1:
            return minutes.count
        default:
            return seconds.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 120
        case 1:
            return 100
        default:
            return 100
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        36
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return "\(hours[row]) 시간"
        case 1:
            return "\(minutes[row]) 분"
        default:
            return "\(seconds[row]) 초"
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hour: Int
        let minute: Int
        let second: Int

        switch component {
        case 0:
            hour = hours[row]
            minute = selectedDuration.minute
            second = selectedDuration.second
        case 1:
            hour = selectedDuration.hour
            minute = minutes[row]
            second = selectedDuration.second
        default:
            hour = selectedDuration.hour
            minute = selectedDuration.minute
            second = seconds[row]
        }

        selectedDuration = ExerciseRecordInputReactor.DurationValue(
            hour: hour,
            minute: minute,
            second: second
        )
        durationChangedRelay.accept(selectedDuration)
    }
}

private extension Int {
    func clamped(to values: [Int]) -> Int {
        guard let minimum = values.first,
              let maximum = values.last
        else { return self }

        return Swift.min(Swift.max(self, minimum), maximum)
    }
}

extension Reactive where Base == DurationPickerSheetView {
    var durationChanged: ControlEvent<ExerciseRecordInputReactor.DurationValue> {
        ControlEvent(events: base.durationChangedRelay)
    }
}
