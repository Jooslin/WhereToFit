//
//  WeightInputView.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/14/26.
//

import SnapKit
import Then
import UIKit

final class WeightInputView: UIView {
    let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .gray600
    }

    let saveButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "저장하기"
    }

    private let currentWeight: CalendarReactor.WeightValue
    private let integerValues = Array(30...200)
    private let decimalValues = Array(0...9)

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

    private let titleLabel = UILabel(text: "몸무게 입력", config: .body14Medium)

    private lazy var pickerView = UIPickerView().then {
        $0.dataSource = self
        $0.delegate = self
    }

    init(currentWeight: CalendarReactor.WeightValue) {
        self.currentWeight = currentWeight

        super.init(frame: .zero)

        setStyle()
        setLayout()
        setPickerValue()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WeightInputView {
    var selectedWeight: CalendarReactor.WeightValue {
        let integer = integerValues[pickerView.selectedRow(inComponent: 0)]
        let decimal = decimalValues[pickerView.selectedRow(inComponent: 2)]
        return CalendarReactor.WeightValue(integer: integer, decimal: decimal)
    }
}

private extension WeightInputView {
    func setStyle() {
        backgroundColor = .clear
    }

    func setLayout() {
        addSubview(dimmedView)
        addSubview(sheetView)

        [
            handleView,
            titleLabel,
            closeButton,
            pickerView,
            saveButton
        ].forEach(sheetView.addSubview)

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(428)
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(38)
            $0.leading.equalToSuperview().offset(16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        pickerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(18)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(240)
            $0.height.equalTo(220)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(48)
        }
    }

    func setPickerValue() {
        if let integerIndex = integerValues.firstIndex(of: currentWeight.integer) {
            pickerView.selectRow(integerIndex, inComponent: 0, animated: false)
        }

        if let decimalIndex = decimalValues.firstIndex(of: currentWeight.decimal) {
            pickerView.selectRow(decimalIndex, inComponent: 2, animated: false)
        }
    }

    func title(forRow row: Int, component: Int) -> String {
        switch component {
        case 0:
            return "\(integerValues[row])"
        case 1:
            return "·"
        case 2:
            return "\(decimalValues[row])"
        case 3:
            return "kg"
        default:
            return ""
        }
    }
}

extension WeightInputView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        4
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return integerValues.count
        case 2:
            return decimalValues.count
        default:
            return 1
        }
    }
}

extension WeightInputView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 76
        case 1:
            return 24
        case 2:
            return 56
        case 3:
            return 54
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        54
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadAllComponents()
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.text = title(forRow: row, component: component)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: isSelected(row: row, component: component) ? .bold : .semibold)
        label.textColor = isSelected(row: row, component: component) ? .black : .gray300

        if component == 3 {
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .black
        }

        return label
    }

    private func isSelected(row: Int, component: Int) -> Bool {
        switch component {
        case 0, 2:
            return pickerView.selectedRow(inComponent: component) == row
        case 1, 3:
            return true
        default:
            return false
        }
    }
}
