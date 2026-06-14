//
//  ButtonConfiguration.swift
//  WhereToFit
//
//  Created by 변예린 on 5/28/26.
//

import UIKit

struct ButtonConfiguration {
    let size: ButtonSize
    let style: ButtonStyle
    let color: UIColor
    let titleColor: UIColor
    let borderColor: UIColor
    
    enum ButtonStyle {
        case fill
        case border
        
        var borderWidth: CGFloat {
            switch self {
            case .fill: return 0
            case .border: return 1
            }
        }
    }
    
    enum ButtonSize {
        // DesignButton
        case small
        case medium
        case large
        
        // OnboardingButton
        case onboarding
        case onboardingCard
        
        // IconButton
        case icon
        
        //additional
        case additionalIcon
        
        var padding: UIEdgeInsets {
            switch self {
            case .small:
                    .init(top: 10, left: 24, bottom: 10, right: 24)
            case .medium, .large:
                    .init(top: 14, left: 0, bottom: 14, right: 0)
            case .onboarding:
                    .init(top: 16, left: 24, bottom: 16, right: 24)
            case .onboardingCard:
                    .init(top: 18, left: 0, bottom: 14, right: 0)
            case .icon:
                    .init(top: 0, left: 0, bottom: 0, right: 0)
            case .additionalIcon:
                    .init(top: 6, left: 10, bottom: 6, right: 12)
            }
        }
        
        var size: CGSize {
            switch self {
            case .small:
                return CGSize(width: 80, height: 38)
            case .medium:
                return CGSize(width: 222, height: 48)
            case .large:
                return CGSize(width: 343, height: 48)
            case .onboarding:
                return CGSize(width: 343, height: 60)
            case .onboardingCard:
                return CGSize(width: 100, height: 100)
            case .icon:
                return CGSize(width: 24, height: 24)
            case .additionalIcon:
                return CGSize(width: 74, height: 29)
            }
        }
        
        var labelConfig: LabelConfiguration {
            switch self {
            case .small:
                return .body12Medium
            case .medium, .large:
                return .body14Semibold
            case .onboarding, .onboardingCard:
                return .title16
            case .icon, .additionalIcon:
                return .body12Medium
            }
        }
    }
}

extension ButtonConfiguration {
    private static func make(
        size: ButtonSize,
        style: ButtonStyle,
        color: UIColor,
        titleColor: UIColor? = nil,
        borderColor: UIColor? = nil
    ) -> ButtonConfiguration {
        ButtonConfiguration(
            size: size,
            style: style,
            color: color,
            titleColor: titleColor ?? size.labelConfig.color,
            borderColor: borderColor ?? size.labelConfig.color
        )
    }
    
    //MARK: Filled
    static let smallFilledBlue = make(size: .small, style: .fill, color: .primary400, titleColor: .white)
    static let mediumFilledBlue = make(size: .medium, style: .fill, color: .primary400, titleColor: .white)
    static let largeFilledBlue = make(size: .large, style: .fill, color: .primary400, titleColor: .white)
    
    static let smallFilledGray = make(size: .small, style: .fill, color: .gray200, titleColor: .white)
    static let mediumFilledGray = make(size: .medium, style: .fill, color: .gray200, titleColor: .white)
    static let largeFilledGray = make(size: .large, style: .fill, color: .gray200, titleColor: .white)
    
    static let smallFilledLightGray = make(size: .small, style: .fill, color: .gray50, titleColor: .gray500)
    static let mediumFilledLightGray = make(size: .medium, style: .fill, color: .gray50, titleColor: .gray500)
    static let largeFilledLightGray = make(size: .large, style: .fill, color: .gray50, titleColor: .gray500)
    
    //MARK: Border
    static let smallBorderBlue = make(size: .small, style: .border, color: .white, titleColor: .primary400)
    static let mediumBorderBlue = make(size: .medium, style: .border, color: .white, titleColor: .primary400)
    static let largeBorderBlue = make(size: .large, style: .border, color: .white, titleColor: .primary400)
    
    //MARK: SelectedBorder
    static let selectedSmallBorderBlue = make(size: .small, style: .border, color: .primary25, titleColor: .primary600, borderColor: .primary200)
    static let selectedOnboarding = make(size: .onboarding, style: .border, color: .primary25, titleColor: .primary600, borderColor: .primary200)
    static let selectedOnboardingCard = make(size: .onboardingCard, style: .border, color: .primary25, titleColor: .primary600, borderColor: .primary200)
    
    //MARK: Onboarding
    static let onboarding = make(size: .onboarding, style: .fill, color: .gray50, titleColor: .gray600)
    static let onboardingCard = make(size: .onboardingCard, style: .fill, color: .gray50, titleColor: .gray600)
    
    //MARK: IconButton
    static let icon = make(size: .icon, style: .fill, color: .clear, titleColor: .gray900)
    
    //MARK: Additional Button
    static let iconAdditional = make(size: .additionalIcon, style: .border, color: .white, titleColor: .gray800, borderColor: .gray200)
    static let selectedIconAdditional = make(size: .additionalIcon, style: .border, color: .primary25, titleColor: .primary600, borderColor: .primary200)
}
