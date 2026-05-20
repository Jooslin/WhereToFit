//
//  ViewController.swift
//  Gymap
//
//  Created by 변예린 on 5/19/26.
//

import UIKit
import RxFlow
import RxRelay
import ReactorKit

class BaseViewController<R: Reactor>: UIViewController, Stepper, ReactorKit.View {
    typealias State = R.State
    typealias Action = R.Action
    
    let steps = PublishRelay<Step>()
    var disposeBag = DisposeBag()
    
    init(reactor: R? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 네비게이션 바가 숨겨져도 스와이프로 뒤로 가기가 가능하도록 설정
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    func bind(reactor: R) {}
}
