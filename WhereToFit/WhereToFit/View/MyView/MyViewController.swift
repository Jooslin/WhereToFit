//
//  MyViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/2/26.
//

import ReactorKit
import UIKit

final class MyViewController: BaseViewController<MyReactor> {
    let myView = MyView()

    override func loadView() {
        view = myView
    }

    override func bind(reactor: MyReactor) {}
}
