//
//  Util.swift
//  Gymap
//
//  Created by 변예린 on 5/19/26.
//

import UIKit
import RxSwift
import RxCocoa

// ViewController의 메서드를 Observable 객체로 사용할 수 있도록 확장
extension Reactive where Base: UIViewController {
    var viewWillAppear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillAppear(_:))).map { _ in }
    }
    
    var viewWillDisappear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillDisappear(_:))).map { _ in }
    }
}
