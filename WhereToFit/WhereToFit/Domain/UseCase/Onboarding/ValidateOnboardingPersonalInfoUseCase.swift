//
//  ValidateOnboardingPersonalInfoUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/20/26.
//

import Foundation

final class ValidateOnboardingPersonalInfoUseCase {
    enum ValidationError: Error {
        case invalidBirthdayFormat
        case invalidHeight
        case invalidWeight

        var title: String {
            switch self {
            case .invalidBirthdayFormat:
                return "생년월일 입력 오류"
            case .invalidHeight:
                return "키 입력 오류"
            case .invalidWeight:
                return "몸무게 입력 오류"
            }
        }

        var message: String {
            switch self {
            case .invalidBirthdayFormat:
                return "생년월일은 yyyymmdd 형식의 실제 날짜로 입력해주세요."
            case .invalidHeight:
                return "키는 0 이상 250 이하의 숫자로 입력해주세요."
            case .invalidWeight:
                return "몸무게는 0 이상 200 이하의 숫자로 입력해주세요."
            }
        }
    }

    private let dateService: DateService

    init(dateService: DateService) {
        self.dateService = dateService
    }

    static func sanitizeBirthdayInput(_ input: String) -> String {
        String(input.filter(\.isNumber).prefix(8))
    }

    static func sanitizeDecimalInput(_ input: String) -> String {
        var hasDecimalSeparator = false

        return input.reduce(into: "") { result, character in
            if character.isNumber {
                result.append(character)
            } else if character == ".", hasDecimalSeparator == false {
                result.append(character)
                hasDecimalSeparator = true
            }
        }
    }

    func validateBirthday(_ input: String) -> Result<Date?, ValidationError> {
        let sanitizedInput = Self.sanitizeBirthdayInput(input)
        guard sanitizedInput.isEmpty == false else {
            return .success(nil)
        }

        guard sanitizedInput.count == 8,
              let year = Int(sanitizedInput.prefix(4)),
              let month = Int(sanitizedInput.dropFirst(4).prefix(2)),
              let day = Int(sanitizedInput.suffix(2)) else {
            return .failure(.invalidBirthdayFormat)
        }

        guard let date = dateService.date(year: year, month: month, day: day) else {
            return .failure(.invalidBirthdayFormat)
        }

        return .success(date)
    }

    func validateHeight(_ input: String) -> Result<Double?, ValidationError> {
        validateDecimalInput(input, maximumValue: 250, error: .invalidHeight)
    }

    func validateWeight(_ input: String) -> Result<Double?, ValidationError> {
        validateDecimalInput(input, maximumValue: 200, error: .invalidWeight)
    }
}

private extension ValidateOnboardingPersonalInfoUseCase {
    func validateDecimalInput(
        _ input: String,
        maximumValue: Double,
        error: ValidationError
    ) -> Result<Double?, ValidationError> {
        let sanitizedInput = ValidateOnboardingPersonalInfoUseCase.sanitizeDecimalInput(input)
        guard sanitizedInput.isEmpty == false else {
            return .success(nil)
        }

        guard let value = Double(sanitizedInput),
              value >= 0,
              value <= maximumValue else {
            return .failure(error)
        }

        return .success(value)
    }
}
