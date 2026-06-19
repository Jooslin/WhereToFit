//
//  ProgramDateReactor.swift
//  WhereToFit
//
//  Created by 변예린 on 6/18/26.
//

import ReactorKit
import Foundation

final class ProgramDateReactor: BaseReactor {
    let initialState: State = State()
    
    enum Action {
        case selectDate(DateComponents)
        case deselectDate(DateComponents)
    }
    
    enum Mutation {
        case setDate(Date)
        case deleteDate(Date)
    }
    
    struct State {
        var dates: Set<Date> = []
    }
    
    //MARK: Properties & Initialize
    private let dateService: DateService
    
    init(dateService: DateService) {
        self.dateService = dateService
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .selectDate(let dateComp):
            let date = dateService.startOfDay(dateComp)
            return .just(.setDate(date))
            
        case .deselectDate(let dateComp):
            let date = dateService.startOfDay(dateComp)
            return .just(.deleteDate(date))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setDate(let date):
            newState.dates.insert(date)
        case .deleteDate(let date):
            newState.dates.remove(date)
        }
        
        return newState
    }
}
