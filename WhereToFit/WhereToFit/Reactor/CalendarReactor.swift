//
//  CalendarReactor.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/10/26.
//

import ReactorKit

final class CalendarReactor: BaseReactor {
    let initialState = State(
        exerciseItems: [
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym),
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym),
            ExerciseItem(title: "수영", duration: "120분", calories: "00칼로리", icon: .gym)
        ]
    )

    enum Action {}

    enum ExerciseIcon: Equatable {
        case gym
    }

    struct ExerciseItem: Equatable {
        let title: String
        let duration: String
        let calories: String
        let icon: ExerciseIcon
    }

    struct State {
        var exerciseItems: [ExerciseItem]
    }
}
