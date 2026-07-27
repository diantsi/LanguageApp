//
//  LearningSummaryFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct LearningSummaryFeature {

    @ObservableState
    struct State: Equatable {
        var completedTermsCount: Int = 0
        var totalExercisesCount: Int = 0
        var termTracks: [UUID: LearningSessionFeature.TermProgressTrack] = [:]
    }

    enum Action: Equatable {
        case restartTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case restart
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .restartTapped:
                return .send(.delegate(.restart))

            case .delegate:
                return .none
            }
        }
    }
}
