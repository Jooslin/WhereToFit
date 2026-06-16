//
//  CalendarConditionValue+Image.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/16/26.
//

import UIKit

extension CalendarReactor.ConditionValue {
    var image: UIImage? {
        switch self {
        case .veryGood:
            return UIImage(resource: .veryGood)
        case .good:
            return UIImage(resource: .good)
        case .normal:
            return UIImage(resource: .normal)
        case .bad:
            return UIImage(resource: .bad)
        case .worst:
            return UIImage(resource: .worst)
        }
    }
}
