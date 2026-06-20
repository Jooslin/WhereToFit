//
//  RegisteredProgramsViewController.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/9/26.
//

import ReactorKit
import RxCocoa
import UIKit

final class RegisteredProgramsViewController: BaseViewController<RegisteredProgramsReactor> {
    let registeredProgramsView = RegisteredProgramsView()
    private var items: [RegisteredProgramsReactor.RegisteredProgramItem] = []

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
            .bind(with: self) { owner, _ in
                owner.steps.accept(AppStep.pageBack)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map(\.items)
            .distinctUntilChanged()
            .bind(with: self) { owner, items in
                owner.items = items
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

        cell.configure(item: items[indexPath.item])
        return cell
    }
}
