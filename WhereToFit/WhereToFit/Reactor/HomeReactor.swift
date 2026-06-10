//
//  HomeReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import ReactorKit

final class HomeReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case viewWillAppear
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setWeeklyDate([WeeklyDate])
    }
    
    struct State {
        var isLoading: Bool = false
        var data: [HomeCollectionView.Section: [HomeCollectionView.Item]] = [:]
    }
    
    //MARK: Properties & Initialize
    private let dateService: DateService
    
    init(dateService: DateService) {
        self.dateService = dateService
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return Observable.concat([
                .just(.setLoading(true))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setWeeklyDate(let weeklyDate):
            newState.data[.weather]
        }
        
        return newState
    }
}

extension HomeReactor {
    private func makeWeathersection() -> Observable<Mutation> {
        Observable.create { [weak self] observer in
            guard let self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let weeklyDate = dateService.weeklyDate()
            observer.onNext(.setWeeklyDate(weeklyDate))
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
