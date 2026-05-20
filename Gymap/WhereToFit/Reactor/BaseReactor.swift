//
//  BaseReactor.swift
//  Gymap
//
//  Created by 변예린 on 5/19/26.
//

import ReactorKit

protocol BaseReactor: AnyObject, Reactor {
}

extension BaseReactor {
  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}
