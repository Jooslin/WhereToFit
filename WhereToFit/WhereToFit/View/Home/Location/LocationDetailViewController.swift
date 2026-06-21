//
//  LocationDetailViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import UIKit
import RxSwift
import ReactorKit
import RxCocoa

final class LocationDetailViewController: BaseViewController<LocationDetailReactor> {
    let detailView = LocationDetailView()
    
    private let selectedAddressRelay = PublishRelay<String>()
    private lazy var keyboardDismissTapGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(didTapBackground)
    )
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keyboardDismissTapGesture.cancelsTouchesInView = false
        keyboardDismissTapGesture.delegate = self
        detailView.addGestureRecognizer(keyboardDismissTapGesture)
    }
    
    override func bind(reactor: LocationDetailReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: LocationDetailReactor) {
        // TitleView
        detailView.rx.backButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { AppStep.pageBack }
            .bind(to: steps)
            .disposed(by: disposeBag)
        
        // 주소 선택
        detailView.addressTextField.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { `self`, _ in
                self.presentPostCodeSelection()
            })
            .disposed(by: disposeBag)
        
        selectedAddressRelay
            .observe(on: MainScheduler.asyncInstance)
            .map { LocationDetailReactor.Action.updateAddress($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.nameTextFieldEditingDidEnd
            .map { LocationDetailReactor.Action.updateName($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.currentLocationButtonTap
            .map {
                LocationDetailReactor.Action.currentLocation
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 버튼
        detailView.rx.homeButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.myHome) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.officeButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.office) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        detailView.rx.addButtonTap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.updateButtonType(.additional) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 등록 버튼
        detailView.registerButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { LocationDetailReactor.Action.update }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: LocationDetailReactor) {
        let state = reactor.state
            .asDriver(
                onErrorJustReturn: .init(address: "", name: "")
            )
        
        state.map(\.address)
            .distinctUntilChanged()
            .drive(detailView.addressTextField.rx.text)
            .disposed(by: disposeBag)
        
        state.map(\.name)
            .distinctUntilChanged()
            .drive(detailView.nameTextField.rx.text)
            .disposed(by: disposeBag)
        
        state.map(\.registerButtonTitle)
            .distinctUntilChanged()
            .drive(
                with: detailView,
                onNext: { detailView, title in
                    detailView.registerButton.title = title
                }
            )
            .disposed(by: disposeBag)
        
        state.map(\.isRegisterButtonEnabled)
            .distinctUntilChanged()
            .drive(detailView.registerButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        state.map(\.buttonType)
            .drive(
                with: detailView,
                onNext: { detailView, buttonType in
                    detailView.configureButtonType(buttonType)
                }
            )
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$updateResult)
            .compactMap { $0 }
            .map {
                $0 ? AppStep.pageBack : AppStep.alert(title: "저장 실패", message: "위치를 저장할 수 없습니다.\n잠시 후 다시 시도해주세요.")
            }
            .bind(to: steps)
            .disposed(by: disposeBag)
    }
}

extension LocationDetailViewController {
    private func presentPostCodeSelection() {
        let vc = KakaoPostCodeViewController()
        vc.onSelectAddress = { [weak self] address in
            self?.selectedAddressRelay.accept(address)
        }
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: false)
    }
    
    @objc private func didTapBackground() {
        detailView.endEditing(true)
    }
}

extension LocationDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard detailView.nameTextField.isFirstResponder else { return false }
        guard let touchView = touch.view else { return true }
        
        return !touchView.isDescendant(of: detailView.nameTextField)
    }
}
