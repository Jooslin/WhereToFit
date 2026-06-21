//
//  SplashViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import UIKit
import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class SplashViewController: BaseViewController<SplashReactor> {
    private let logoLabel = UILabel(text: "WhereToFit", config: .title24, color: .gray900).then {
        $0.textAlignment = .center
    }
    private let indicatorView = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = false
        $0.startAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        reactor?.action.onNext(.viewDidLoad)
    }
    
    override func bind(reactor: SplashReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: SplashReactor) {
    }
    
    private func bindState(reactor: SplashReactor) {
        reactor.state
            .compactMap(\.destination)
            .take(1)
            .bind(with: self) { owner, step in
                owner.steps.accept(step)
            }
            .disposed(by: disposeBag)
    }
}

private extension SplashViewController {
    func setLayout() {
        view.backgroundColor = .white
        
        view.addSubview(logoLabel)
        view.addSubview(indicatorView)
        
        logoLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(32)
        }
        
        indicatorView.snp.makeConstraints {
            $0.top.equalTo(logoLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
    }
}
