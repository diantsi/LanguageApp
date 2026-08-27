//
//  FlashcardFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct FlashcardFeature {

    enum FirstSide: Equatable, CaseIterable {
        case term
        case translation

        var title: String {
            switch self {
            case .term: return "Термін"
            case .translation: return "Переклад"
            }
        }
        
        mutating func toggle() {
            self = (self == .term) ? .translation : .term
        }
    }

    enum VisibleSide: Equatable {
        case term
        case translation
    }

    struct CardFace: Equatable {
        let text: String
        let hint: String?
        let label: String
    }

    struct CardSides: Equatable {
        let front: CardFace
        let back: CardFace
    }

    @ObservableState
    struct State: Equatable {
        var cards: [Term] = []
        var currentIndex: Int = 0
        var isFlipped: Bool = false
        var firstSide: FirstSide = .term
        var isLoading: Bool = false

        var sessionId: UUID = UUID()

        init(
            cards: [Term] = [],
            currentIndex: Int = 0,
            isFlipped: Bool = false,
            firstSide: FirstSide = .term,
            isLoading: Bool = false,
            sessionId: UUID = UUID()
        ) {
            self.cards = cards
            self.currentIndex = currentIndex
            self.isFlipped = isFlipped
            self.firstSide = firstSide
            self.isLoading = isLoading
            self.sessionId = sessionId
        }

        var currentCard: Term? {
            guard !cards.isEmpty, cards.indices.contains(currentIndex) else {
                return nil
            }
            return cards[currentIndex]
        }

        var currentCardSides: CardSides? {
            guard let card = currentCard else { return nil }
            switch firstSide {
            case .term:
                return CardSides(
                    front: CardFace(
                        text: card.termText,
                        hint: nil,
                        label: "термін"
                    ),
                    back: CardFace(
                        text: card.translation,
                        hint: card.hint,
                        label: "переклад"
                    )
                )
            case .translation:
                return CardSides(
                    front: CardFace(
                        text: card.translation,
                        hint: card.hint,
                        label: "переклад"
                    ),
                    back: CardFace(
                        text: card.termText,
                        hint: nil,
                        label: "термін"
                    )
                )
            }
        }

        var counter: String {
            guard !cards.isEmpty else { return "" }
            return "\(currentIndex + 1) / \(cards.count)"
        }

        var isEmpty: Bool {
            !isLoading && cards.isEmpty
        }

        var canGoNext: Bool {
            currentIndex < cards.count - 1
        }

        var canGoPrevious: Bool {
            currentIndex > 0
        }

        var visibleSide: VisibleSide {
            switch (firstSide, isFlipped) {
            case (.term, false): return .term
            case (.term, true): return .translation
            case (.translation, false): return .translation
            case (.translation, true): return .term
            }
        }
    }

    enum Action: Equatable {
        case onAppear
        case fetchTermsSuccess([Term])
        case fetchTermsFailure
        case flipCard
        case nextCard
        case previousCard
        case restartSession
        case firstSideChanged
        case voiceButtonTapped
        case goToDictionaryTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case goToDictionary
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.speechClient) var speechClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                state.isLoading = true
                state.isFlipped = false
                let sessionId = state.sessionId
                return .run { [speechClient] send in
                    await speechClient.stop()
                    do {
                        let terms = try await persistenceClient.fetchTerms(sessionId, nil, nil, nil, nil)
                        await send(.fetchTermsSuccess(terms))
                    } catch {
                        await send(.fetchTermsFailure)
                    }
                }

            case .fetchTermsSuccess(let terms):
                state.isLoading = false
                state.cards = terms.shuffled()
                state.currentIndex = 0
                state.isFlipped = false
                return .none

            case .fetchTermsFailure:
                state.isLoading = false
                return .none

            case .flipCard:
                state.isFlipped.toggle()
                return .none

            case .nextCard:
                guard state.canGoNext else { return .none }
                state.currentIndex += 1
                state.isFlipped = false
                return .run { [speechClient] _ in await speechClient.stop() }

            case .previousCard:
                guard state.canGoPrevious else { return .none }
                state.currentIndex -= 1
                state.isFlipped = false
                return .run { [speechClient] _ in await speechClient.stop() }

            case .restartSession:
                state.cards = state.cards.shuffled()
                state.currentIndex = 0
                state.isFlipped = false
                return .run { [speechClient] _ in await speechClient.stop() }

            case .firstSideChanged:
                state.firstSide.toggle()
                state.isFlipped = false
                return .none

            case .voiceButtonTapped:
                guard let card = state.currentCard else { return .none }
                let text: String
                let language: Language
                switch state.visibleSide {
                case .term:
                    text = card.termText
                    language = card.termLanguage
                case .translation:
                    text = card.translation
                    language = card.translationLanguage
                }
                return .run { [speechClient, text, language] _ in
                    await speechClient.speak(text, language)
                }

            case .goToDictionaryTapped:
                return .send(.delegate(.goToDictionary))

            case .delegate:
                return .none
            }
        }
    }
}
