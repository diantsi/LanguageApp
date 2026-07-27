//
//  LearningSessionFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct LearningSessionFeature {

    struct TermProgressTrack: Equatable {
        var correctCount: Int = 0
        var totalExercises: Int = 0
        var completedExercises: Int = 0
        var finalRating: Rating? = nil

        init(correctCount: Int = 0, totalExercises: Int = 0, completedExercises: Int = 0, finalRating: Rating? = nil) {
            self.correctCount = correctCount
            self.totalExercises = totalExercises
            self.completedExercises = completedExercises
            self.finalRating = finalRating
        }
    }

    @ObservableState
    struct State: Equatable {
        var exercises: [Exercise] = []
        var currentIndex: Int = 0
        var userAnswer: String = ""
        var selectedOption: String? = nil
        var isAnswerSubmitted: Bool = false
        var isCurrentAnswerCorrect: Bool = false
        var validationResult: ValidationResult? = nil
        var isOverridden: Bool = false
        var termTracks: [UUID: TermProgressTrack] = [:]
        var errorMessage: String? = nil

        init(
            exercises: [Exercise] = [],
            currentIndex: Int = 0,
            userAnswer: String = "",
            selectedOption: String? = nil,
            isAnswerSubmitted: Bool = false,
            isCurrentAnswerCorrect: Bool = false,
            validationResult: ValidationResult? = nil,
            isOverridden: Bool = false,
            termTracks: [UUID: TermProgressTrack] = [:],
            errorMessage: String? = nil
        ) {
            self.exercises = exercises
            self.currentIndex = currentIndex
            self.userAnswer = userAnswer
            self.selectedOption = selectedOption
            self.isAnswerSubmitted = isAnswerSubmitted
            self.isCurrentAnswerCorrect = isCurrentAnswerCorrect
            self.validationResult = validationResult
            self.isOverridden = isOverridden
            self.termTracks = termTracks
            self.errorMessage = errorMessage
        }

        init(terms: [Term], uuid: () -> UUID = { UUID() }) {
            let hasMultipleChoice = terms.count >= 4

            var mcExercises: [Exercise] = []
            var otherExercises: [Exercise] = []
            var tracks: [UUID: TermProgressTrack] = [:]

            for term in terms {
                let totalExercises = hasMultipleChoice ? 4 : 3
                tracks[term.id] = TermProgressTrack(
                    correctCount: 0,
                    totalExercises: totalExercises,
                    completedExercises: 0
                )

                if hasMultipleChoice {
                    let distractors = terms
                        .filter { $0.id != term.id }
                        .shuffled()
                        .prefix(3)
                        .map { $0.termText }

                    var options = distractors + [term.termText]
                    options.shuffle()

                    let mc = Exercise(
                        id: uuid(),
                        term: term,
                        type: .multipleChoice,
                        prompt: term.translation,
                        targetAnswer: term.termText,
                        options: options
                    )
                    mcExercises.append(mc)
                }

                let wt = Exercise(
                    id: uuid(),
                    term: term,
                    type: .writeTerm,
                    prompt: term.translation,
                    targetAnswer: term.termText
                )
                otherExercises.append(wt)

                let wtr = Exercise(
                    id: uuid(),
                    term: term,
                    type: .writeTranslation,
                    prompt: term.termText,
                    targetAnswer: term.translation
                )
                otherExercises.append(wtr)

                let lst = Exercise(
                    id: uuid(),
                    term: term,
                    type: .listening,
                    prompt: term.termText,
                    targetAnswer: term.termText
                )
                otherExercises.append(lst)
            }

            mcExercises.shuffle()
            otherExercises.shuffle()

            self.exercises = mcExercises + otherExercises
            self.termTracks = tracks
        }

        var currentExercise: Exercise? {
            guard exercises.indices.contains(currentIndex) else { return nil }
            return exercises[currentIndex]
        }

        var isSubmitDisabled: Bool {
            guard let exercise = currentExercise else { return true }
            if exercise.type == .multipleChoice {
                return selectedOption == nil
            } else {
                return userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }

        var completedTermsCount: Int {
            termTracks.values.filter { $0.completedExercises == $0.totalExercises && $0.totalExercises > 0 }.count
        }

        var totalTermsInSession: Int {
            termTracks.count
        }
    }

    enum Action: Equatable {
        case selectOption(String)
        case setUserAnswer(String)
        case submitAnswer
        case markAsCorrect
        case markAsIncorrect
        case nextExercise
        case playListeningAudio
        case updateProgressSuccess
        case updateProgressFailure(String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case sessionFinished(completedTermsCount: Int, totalExercisesCount: Int, termTracks: [UUID: TermProgressTrack])
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.fsrsClient) var fsrsClient
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectOption(option):
                guard !state.isAnswerSubmitted else { return .none }
                state.selectedOption = option
                state.userAnswer = option
                return .none

            case let .setUserAnswer(answer):
                guard !state.isAnswerSubmitted else { return .none }
                state.userAnswer = answer
                return .none

            case .submitAnswer:
                guard !state.isAnswerSubmitted, let current = state.currentExercise else { return .none }

                let answerToValidate: String
                if current.type == .multipleChoice {
                    answerToValidate = state.selectedOption ?? ""
                } else {
                    answerToValidate = state.userAnswer
                }

                let result = AnswerValidator.validateResult(userAnswer: answerToValidate, targetAnswer: current.targetAnswer)
                state.validationResult = result

                let isCorrect = result == .correct
                state.isCurrentAnswerCorrect = isCorrect
                state.isAnswerSubmitted = true
                state.isOverridden = false

                let termId = current.term.id
                var track = state.termTracks[termId] ?? TermProgressTrack()
                if isCorrect {
                    track.correctCount += 1
                }
                track.completedExercises += 1
                state.termTracks[termId] = track

                if track.completedExercises == track.totalExercises {
                    let rating = Rating.calculate(correctCount: track.correctCount, totalExercises: track.totalExercises)
                    state.termTracks[termId]?.finalRating = rating

                    let currentDate = now
                    return .run { [persistenceClient, fsrsClient] send in
                        do {
                            let currentProgress = try await persistenceClient.fetchLearningProgress(termId) ?? LearningProgress(dueDate: currentDate)
                            let updatedProgress = fsrsClient.schedule(currentProgress, rating, currentDate)
                            try await persistenceClient.updateLearningProgress(termId, updatedProgress)
                            await send(.updateProgressSuccess)
                        } catch {
                            await send(.updateProgressFailure(error.localizedDescription))
                        }
                    }
                }

                return .none

            case .markAsCorrect:
                guard state.isAnswerSubmitted, !state.isCurrentAnswerCorrect, let current = state.currentExercise else { return .none }

                state.isCurrentAnswerCorrect = true
                state.isOverridden = true

                let termId = current.term.id
                var track = state.termTracks[termId] ?? TermProgressTrack()
                track.correctCount += 1
                state.termTracks[termId] = track

                if track.completedExercises == track.totalExercises {
                    let rating = Rating.calculate(correctCount: track.correctCount, totalExercises: track.totalExercises)
                    state.termTracks[termId]?.finalRating = rating

                    let currentDate = now
                    return .run { [persistenceClient, fsrsClient] send in
                        do {
                            let currentProgress = try await persistenceClient.fetchLearningProgress(termId) ?? LearningProgress(dueDate: currentDate)
                            let updatedProgress = fsrsClient.schedule(currentProgress, rating, currentDate)
                            try await persistenceClient.updateLearningProgress(termId, updatedProgress)
                            await send(.updateProgressSuccess)
                        } catch {
                            await send(.updateProgressFailure(error.localizedDescription))
                        }
                    }
                }
                return .none

            case .markAsIncorrect:
                guard state.isAnswerSubmitted, state.isCurrentAnswerCorrect, let current = state.currentExercise else { return .none }

                state.isCurrentAnswerCorrect = false
                state.isOverridden = true

                let termId = current.term.id
                var track = state.termTracks[termId] ?? TermProgressTrack()
                track.correctCount = max(0, track.correctCount - 1)
                state.termTracks[termId] = track

                if track.completedExercises == track.totalExercises {
                    let rating = Rating.calculate(correctCount: track.correctCount, totalExercises: track.totalExercises)
                    state.termTracks[termId]?.finalRating = rating

                    let currentDate = now
                    return .run { [persistenceClient, fsrsClient] send in
                        do {
                            let currentProgress = try await persistenceClient.fetchLearningProgress(termId) ?? LearningProgress(dueDate: currentDate)
                            let updatedProgress = fsrsClient.schedule(currentProgress, rating, currentDate)
                            try await persistenceClient.updateLearningProgress(termId, updatedProgress)
                            await send(.updateProgressSuccess)
                        } catch {
                            await send(.updateProgressFailure(error.localizedDescription))
                        }
                    }
                }
                return .none

            case let .updateProgressFailure(message):
                state.errorMessage = message
                return .none

            case .updateProgressSuccess:
                return .none

            case .nextExercise:
                if state.currentIndex + 1 < state.exercises.count {
                    state.currentIndex += 1
                    state.userAnswer = ""
                    state.selectedOption = nil
                    state.isAnswerSubmitted = false
                    state.isCurrentAnswerCorrect = false
                    state.validationResult = nil
                    state.isOverridden = false

                    if let nextEx = state.currentExercise, nextEx.type == .listening {
                        let termText = nextEx.term.termText
                        let termLanguage = nextEx.term.termLanguage
                        return .run { [speechClient] _ in
                            await speechClient.speak(termText, termLanguage)
                        }
                    }
                    return .none
                } else {
                    let completedTerms = state.completedTermsCount
                    let totalEx = state.exercises.count
                    let tracks = state.termTracks
                    return .send(.delegate(.sessionFinished(completedTermsCount: completedTerms, totalExercisesCount: totalEx, termTracks: tracks)))
                }

            case .playListeningAudio:
                if let current = state.currentExercise {
                    let termText = current.term.termText
                    let termLanguage = current.term.termLanguage
                    return .run { [speechClient] _ in
                        await speechClient.speak(termText, termLanguage)
                    }
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
