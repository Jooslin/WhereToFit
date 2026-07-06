//
//  RegisteredProgramsViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

final class RegisteredProgramsViewController: BaseViewController<RegisteredProgramsReactor> {
    let registeredProgramsView = RegisteredProgramsView()
    private var items: [RegisteredProgramsReactor.RegisteredProgramItem] = []
    private var isEditingPrograms = false

    override func loadView() {
        view = registeredProgramsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registeredProgramsView.collectionView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.viewWillAppear)
    }

    override func bind(reactor: RegisteredProgramsReactor) {
        registeredProgramsView.titleView.rx.leftButtonTap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        registeredProgramsView.editButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .map { RegisteredProgramsReactor.Action.toggleEditing }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map(\.items)
            .distinctUntilChanged()
            .bind(with: self) { owner, items in
                owner.items = items
                owner.registeredProgramsView.collectionView.reloadData()
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isEditing)
            .distinctUntilChanged()
            .bind(with: self) { owner, isEditing in
                owner.isEditingPrograms = isEditing
                owner.registeredProgramsView.editButton.setTitle(isEditing ? "완료" : "편집", for: .normal)
                owner.registeredProgramsView.collectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }
}

extension RegisteredProgramsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RegisteredProgramCell.reuseIdentifier,
            for: indexPath
        ) as? RegisteredProgramCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item]
        cell.configure(item: item, isEditing: isEditingPrograms)
        cell.deleteButtonTapped = { [weak self] in
            self?.presentRemoveRegisteredProgramAlert(item)
        }
        return cell
    }
}

private extension RegisteredProgramsViewController {
    func presentRemoveRegisteredProgramAlert(_ item: RegisteredProgramsReactor.RegisteredProgramItem) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: "등록한 프로그램을 삭제할까요?",
            message: "\(item.programName)을(를) 등록 목록에서 삭제합니다.",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let removeAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.removeProgram(item))
        }

        alert.addAction(cancelAction)
        alert.addAction(removeAction)
        present(alert, animated: true)
    }
}
