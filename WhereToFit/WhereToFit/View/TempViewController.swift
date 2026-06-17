//
//  MainViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 5/20/26.
//

import UIKit
import ReactorKit
import SnapKit
import Then

final class TempViewController: BaseViewController<TempReactor> {
    let tempView = ProgramRegisterView()
    
    override func loadView() {
        view = tempView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func bind(reactor: TempReactor) {
        
    }
}

final class TempReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        
    }
    
    struct State {}
}

#Preview {
    TempViewController(reactor: TempReactor())
}
