//
//  LearningSetupFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct LearningSetupFeature {

    static let maxDailyTermsLimit: Int = 100

    @ObservableState
    struct State: Equatable {
        var termsToLearn: [Term] = []
        var userLimit: Int = 0
        var qTermsLearned: Int = 0
        var isLoading: Bool = false
        var errorMessage: String? = nil

        var sessionId: UUID = UUID()

        var session: LearningSessionFeature.State?
        var summary: LearningSummaryFeature.State?

        init(
            termsToLearn: [Term] = [],
            userLimit: Int = 0,
            qTermsLearned: Int = 0,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            sessionId: UUID = UUID(),
            session: LearningSessionFeature.State? = nil,
            summary: LearningSummaryFeature.State? = nil
        ) {
            self.termsToLearn = termsToLearn
            self.userLimit = userLimit
            self.qTermsLearned = qTermsLearned
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.sessionId = sessionId
            self.session = session
            self.summary = summary
        }

        /// Total terms available for learning today
        var termsLimit: Int {
            termsToLearn.count
        }
    }

    enum Action: Equatable {
        case onAppear
        case fetchDueTermsSuccess([Term])
        case fetchDueTermsFailure(String)
        case limitChanged(Int)
        case startLearningTapped

        case session(LearningSessionFeature.Action)
        case summary(LearningSummaryFeature.Action)
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let curDate = now
                let maxCap = Self.maxDailyTermsLimit
                let sessionId = state.sessionId
                return .run { [persistenceClient] send in
                    do {
                        let terms = try await persistenceClient.fetchDueTerms(sessionId, curDate, maxCap)
                        await send(.fetchDueTermsSuccess(terms))
                    } catch {
                        await send(.fetchDueTermsFailure(error.localizedDescription))
                    }
                }

            case let .fetchDueTermsSuccess(terms):
                state.termsToLearn = terms
                state.isLoading = false
                if terms.isEmpty {
                    state.userLimit = 0
                } else {
                    state.userLimit = min(10, terms.count)
                }
                return .none

            case let .fetchDueTermsFailure(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .limitChanged(limit):
                let maxVal = max(1, state.termsLimit)
                state.userLimit = min(max(1, limit), maxVal)
                return .none

            case .startLearningTapped:
                guard !state.termsToLearn.isEmpty else { return .none }
                let termsForSession = Array(state.termsToLearn.prefix(state.userLimit))
                let currentUuid = uuid
                state.session = LearningSessionFeature.State(terms: termsForSession, uuid: { currentUuid() })
                return .none

            case let .session(.delegate(.sessionFinished(completedCount, totalEx, tracks))):
                state.summary = LearningSummaryFeature.State(
                    completedTermsCount: completedCount,
                    totalExercisesCount: totalEx,
                    termTracks: tracks
                )
                state.qTermsLearned += completedCount
                state.session = nil
                return .none

            case .summary(.delegate(.restart)):
                state.summary = nil
                state.session = nil
                return .send(.onAppear)

            case .session, .summary:
                return .none
            }
        }
        .ifLet(\.session, action: \.session) {
            LearningSessionFeature()
        }
        .ifLet(\.summary, action: \.summary) {
            LearningSummaryFeature()
        }
    }
}
