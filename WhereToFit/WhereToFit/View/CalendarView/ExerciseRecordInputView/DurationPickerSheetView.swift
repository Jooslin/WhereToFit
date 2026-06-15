//
//  DurationPickerSheetView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/15/26.
//

import SnapKit
import Then
import UIKit

final class DurationPickerSheetView: UIView {
    let selectButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "선택하기"
    }

    var selectedDurationText: String {
        var components: [String] = []

        if selectedHour > 0 {
            components.append("\(selectedHour)시간")
        }

        if selectedMinute > 0 {
            components.append("\(selectedMinute)분")
        }

        if selectedSecond > 0 {
            components.append("\(selectedSecond)초")
        }

        return components.isEmpty ? "0분" : components.joined(separator: " ")
    }

    private let pickerView = UIPickerView()
    private let hours = Array(0...12)
    private let minutes = Array(0...59)
    private let seconds = Array(0...59)
    private var selectedHour = 0
    private var selectedMinute = 30
    private var selectedSecond = 0

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }

    private let sheetView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray200
        $0.layer.cornerRadius = 2
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

private extension DurationPickerSheetView {
    func setStyle() {
        backgroundColor = .clear
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            handleView,
            titleLabel,
            pickerView,
            selectButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(40)
            $0.leading.equalToSuperview().offset(16)
        }

        pickerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(22)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(168)
        }

        selectButton.snp.makeConstraints {
            $0.top.equalTo(pickerView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setPicker() {
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedHour, inComponent: 0, animated: false)
        pickerView.selectRow(selectedMinute, inComponent: 1, animated: false)
        pickerView.selectRow(selectedSecond, inComponent: 2, animated: false)
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
            return "\(hours[row]) hours"
        case 1:
            return "\(minutes[row]) min"
        default:
            return "\(seconds[row]) sec"
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedHour = hours[row]
        case 1:
            selectedMinute = minutes[row]
        default:
            selectedSecond = seconds[row]
        }
    }
}
