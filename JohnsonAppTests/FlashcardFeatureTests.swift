//
//  FlashcardFeatureTests.swift
//  JohnsonAppTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import JohnsonApp

@MainActor
struct FlashcardFeatureTests {

    // MARK: - Helpers

    private static let term1 = Term(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        termText: "apple",
        translation: "яблуко",
        hint: "фрукт"
    )

    private static let term2 = Term(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        termText: "cat",
        translation: "кіт"
    )

    private static let term3 = Term(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        termText: "dog",
        translation: "пес"
    )

    private static let mockTerms = [term1, term2, term3]

    // MARK: - onAppear

    @Test
    func testOnAppearLoadsAndShufflesTerms() async {
        let store = TestStore(initialState: FlashcardFeature.State()) {
            FlashcardFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, _ in Self.mockTerms }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.fetchTermsSuccess)

        #expect(store.state.cards.count == 3)
        #expect(Set(store.state.cards.map(\.id)) == Set(Self.mockTerms.map(\.id)))
        #expect(store.state.currentIndex == 0)
        #expect(store.state.isFlipped == false)
        #expect(store.state.isLoading == false)
    }

    @Test
    func testOnAppearSetsLoadingTrue() async {
        let store = TestStore(initialState: FlashcardFeature.State()) {
            FlashcardFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, _ in [] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.fetchTermsSuccess) {
            $0.isLoading = false
        }
    }

    // MARK: - Flip

    @Test
    func testFlipCardTogglesIsFlipped() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                isFlipped: false
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.flipCard) {
            $0.isFlipped = true
        }

        await store.send(.flipCard) {
            $0.isFlipped = false
        }
    }

    // MARK: - Next / Previous

    @Test
    func testNextCardIncrementsIndexAndResetsFlip() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0,
                isFlipped: true
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.nextCard) {
            $0.currentIndex = 1
            $0.isFlipped = false
        }
    }

    @Test
    func testPreviousCardDecrementsIndexAndResetsFlip() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 2,
                isFlipped: true
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.previousCard) {
            $0.currentIndex = 1
            $0.isFlipped = false
        }
    }

    @Test
    func testNextCardAtLastCardDoesNothing() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 2
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.nextCard)
    }

    @Test
    func testPreviousCardAtFirstCardDoesNothing() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.previousCard)
    }

    // MARK: - Restart

    @Test
    func testRestartSessionResetsIndexAndFlip() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 2,
                isFlipped: true
            )
        ) {
            FlashcardFeature()
        }
        store.exhaustivity = .off

        await store.send(.restartSession) {
            $0.currentIndex = 0
            $0.isFlipped = false
        }
    }

    // MARK: - First Side

    @Test
    func testFirstSideChangedUpdatesSideAndResetsFlip() async {
        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                isFlipped: true,
                firstSide: .term
            )
        ) {
            FlashcardFeature()
        }

        await store.send(.firstSideChanged(.translation)) {
            $0.firstSide = .translation
            $0.isFlipped = false
        }
    }

    // MARK: - Empty State

    @Test
    func testEmptyStateWhenNoTerms() async {
        let store = TestStore(initialState: FlashcardFeature.State()) {
            FlashcardFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, _ in [] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.fetchTermsSuccess) {
            $0.isLoading = false
            $0.cards = []
        }

        #expect(store.state.isEmpty)
    }

    // MARK: - Delegate

    @Test
    func testGoToDictionaryTappedSendsDelegate() async {
        let store = TestStore(
            initialState: FlashcardFeature.State()
        ) {
            FlashcardFeature()
        }

        await store.send(.goToDictionaryTapped)
        await store.receive(\.delegate.goToDictionary)
    }

    // MARK: - Visible Side

    @Test
    func testVisibleSideTermFirstNotFlipped() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            isFlipped: false,
            firstSide: .term
        )
        #expect(state.visibleSide == .term)
    }

    @Test
    func testVisibleSideTermFirstFlipped() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            isFlipped: true,
            firstSide: .term
        )
        #expect(state.visibleSide == .translation)
    }

    @Test
    func testVisibleSideTranslationFirstNotFlipped() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            isFlipped: false,
            firstSide: .translation
        )
        #expect(state.visibleSide == .translation)
    }

    @Test
    func testVisibleSideTranslationFirstFlipped() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            isFlipped: true,
            firstSide: .translation
        )
        #expect(state.visibleSide == .term)
    }

    // MARK: - Card Sides Formatting

    @Test
    func testCurrentCardSidesWhenTermFirst() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            currentIndex: 0,
            firstSide: .term
        )
        let sides = state.currentCardSides
        #expect(sides != nil)
        #expect(sides?.front.text == "apple")
        #expect(sides?.front.hint == nil)
        #expect(sides?.front.label == "термін")

        #expect(sides?.back.text == "яблуко")
        #expect(sides?.back.hint == "фрукт")
        #expect(sides?.back.label == "переклад")
    }

    @Test
    func testCurrentCardSidesWhenTranslationFirst() {
        let state = FlashcardFeature.State(
            cards: Self.mockTerms,
            currentIndex: 0,
            firstSide: .translation
        )
        let sides = state.currentCardSides
        #expect(sides != nil)
        #expect(sides?.front.text == "яблуко")
        #expect(sides?.front.hint == "фрукт")
        #expect(sides?.front.label == "переклад")

        #expect(sides?.back.text == "apple")
        #expect(sides?.back.hint == nil)
        #expect(sides?.back.label == "термін")
    }

    // MARK: - Counter

    @Test
    func testCounterStringReflectsCurrentIndex() {
        var state = FlashcardFeature.State(cards: Self.mockTerms, currentIndex: 0)
        #expect(state.counter == "1 / 3")

        state.currentIndex = 1
        #expect(state.counter == "2 / 3")

        state.currentIndex = 2
        #expect(state.counter == "3 / 3")
    }

    @Test
    func testCounterStringEmptyWhenNoCards() {
        let state = FlashcardFeature.State()
        #expect(state.counter == "")
    }

    // MARK: - canGoNext / canGoPrevious

    @Test
    func testCanGoNextAndPrevious() {
        var state = FlashcardFeature.State(cards: Self.mockTerms, currentIndex: 0)
        #expect(!state.canGoPrevious)
        #expect(state.canGoNext)

        state.currentIndex = 1
        #expect(state.canGoPrevious)
        #expect(state.canGoNext)

        state.currentIndex = 2
        #expect(state.canGoPrevious)
        #expect(!state.canGoNext)
    }

    // MARK: - Pronunciation

    @Test
    func testVoiceButtonTappedSpeaksTermWhenTermSideVisible() async {
        var spokenText: String?
        var spokenLanguage: Language?

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0,
                isFlipped: false,
                firstSide: .term
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.speak = { text, language in
                spokenText = text
                spokenLanguage = language
            }
            $0.speechClient.stop = {}
        }

        await store.send(.voiceButtonTapped)

        #expect(spokenText == "apple")
        #expect(spokenLanguage == .english)
    }

    @Test
    func testVoiceButtonTappedSpeaksTranslationWhenTranslationSideVisible() async {
        var spokenText: String?
        var spokenLanguage: Language?

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0,
                isFlipped: false,
                firstSide: .translation
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.speak = { text, language in
                spokenText = text
                spokenLanguage = language
            }
            $0.speechClient.stop = {}
        }

        await store.send(.voiceButtonTapped)

        #expect(spokenText == "яблуко")
        #expect(spokenLanguage == .ukrainian)
    }

    @Test
    func testVoiceButtonTappedSpeaksTranslationAfterFlip() async {
        var spokenText: String?
        var spokenLanguage: Language?

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0,
                isFlipped: true,
                firstSide: .term
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.speak = { text, language in
                spokenText = text
                spokenLanguage = language
            }
            $0.speechClient.stop = {}
        }

        await store.send(.voiceButtonTapped)

        #expect(spokenText == "яблуко")
        #expect(spokenLanguage == .ukrainian)
    }

    @Test
    func testVoiceButtonTappedDoesNothingWhenNoCard() async {
        var speakCalled = false

        let store = TestStore(
            initialState: FlashcardFeature.State(cards: [])
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.speak = { _, _ in speakCalled = true }
            $0.speechClient.stop = {}
        }

        await store.send(.voiceButtonTapped)

        #expect(!speakCalled)
    }

    @Test
    func testNextCardStopsSpeech() async {
        var stopCalled = false

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 0
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.stop = { stopCalled = true }
            $0.speechClient.speak = { _, _ in }
        }

        await store.send(.nextCard) {
            $0.currentIndex = 1
            $0.isFlipped = false
        }

        #expect(stopCalled)
    }

    @Test
    func testPreviousCardStopsSpeech() async {
        var stopCalled = false

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 1
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.stop = { stopCalled = true }
            $0.speechClient.speak = { _, _ in }
        }

        await store.send(.previousCard) {
            $0.currentIndex = 0
            $0.isFlipped = false
        }

        #expect(stopCalled)
    }

    @Test
    func testRestartSessionStopsSpeech() async {
        var stopCalled = false

        let store = TestStore(
            initialState: FlashcardFeature.State(
                cards: Self.mockTerms,
                currentIndex: 2,
                isFlipped: true
            )
        ) {
            FlashcardFeature()
        } withDependencies: {
            $0.speechClient.stop = { stopCalled = true }
            $0.speechClient.speak = { _, _ in }
        }
        store.exhaustivity = .off

        await store.send(.restartSession) {
            $0.currentIndex = 0
            $0.isFlipped = false
        }

        #expect(stopCalled)
    }
}
