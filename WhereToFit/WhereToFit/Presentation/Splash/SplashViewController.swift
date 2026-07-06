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
    private enum Layout {
        static let logoSize = CGSize(width: 138, height: 98)
        static let logoTopOffset = 196
    }
    
    private let logoImageView = UIImageView(image: UIImage(named: "appLogo")).then {
        $0.contentMode = .scaleAspectFit
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
        view.backgroundColor = .systemBackground
        
        view.addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.logoTopOffset)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(Layout.logoSize)
        }
    }
}
