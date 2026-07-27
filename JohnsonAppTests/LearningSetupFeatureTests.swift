//
//  LearningSetupFeatureTests.swift
//  JohnsonAppTests
//

import ComposableArchitecture
import Foundation
import Testing
import XCTest
@testable import JohnsonApp

@MainActor
struct LearningSetupFeatureTests {

    // MARK: - AnswerValidator Tests

    @Test
    func testAnswerNormalization() {
        #expect(AnswerValidator.normalize("  Apple.  ") == "apple")
        #expect(AnswerValidator.normalize("Hello   world!") == "hello world")
        #expect(AnswerValidator.normalize("  TEST,  ") == "test")
        #expect(AnswerValidator.normalize("What?") == "what")
    }

    @Test
    func testAnswerValidationMatching() {
        #expect(AnswerValidator.validate(userAnswer: "  apple. ", targetAnswer: "Apple"))
        #expect(AnswerValidator.validate(userAnswer: "take   off", targetAnswer: "take off!"))
        #expect(!AnswerValidator.validate(userAnswer: "banana", targetAnswer: "apple"))
    }

    // MARK: - Rating Calculation Tests

    @Test
    func testRatingCalculationWithFourExercises() {
        #expect(LearningSessionFeature.calculateRating(correctCount: 0, totalExercises: 4) == .again)
        #expect(LearningSessionFeature.calculateRating(correctCount: 1, totalExercises: 4) == .again)
        #expect(LearningSessionFeature.calculateRating(correctCount: 2, totalExercises: 4) == .hard)
        #expect(LearningSessionFeature.calculateRating(correctCount: 3, totalExercises: 4) == .good)
        #expect(LearningSessionFeature.calculateRating(correctCount: 4, totalExercises: 4) == .easy)
    }

    @Test
    func testRatingCalculationWithThreeExercises() {
        #expect(LearningSessionFeature.calculateRating(correctCount: 0, totalExercises: 3) == .again)
        #expect(LearningSessionFeature.calculateRating(correctCount: 1, totalExercises: 3) == .hard)
        #expect(LearningSessionFeature.calculateRating(correctCount: 2, totalExercises: 3) == .good)
        #expect(LearningSessionFeature.calculateRating(correctCount: 3, totalExercises: 3) == .easy)
    }

    // MARK: - LearningSetupFeature Tests

    private static func makeTerm(
        id: UUID = UUID(),
        termText: String,
        translation: String
    ) -> Term {
        Term(
            id: id,
            termText: termText,
            translation: translation,
            termLanguage: .english,
            translationLanguage: .ukrainian,
            status: .new
        )
    }

    @Test
    func testOnAppearLoadsDueTerms() async {
        let term1 = Self.makeTerm(termText: "apple", translation: "яблуко")
        let term2 = Self.makeTerm(termText: "banana", translation: "банан")

        let store = TestStore(initialState: LearningSetupFeature.State()) {
            LearningSetupFeature()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSince1970: 1000)
            $0.persistenceClient.fetchDueTerms = { _, _ in [term1, term2] }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.fetchDueTermsSuccess)

        #expect(store.state.termsToLearn == [term1, term2])
        #expect(store.state.termsLimit == 2)
        #expect(store.state.userLimit == 2)
        #expect(store.state.isLoading == false)
    }

    @Test
    func testLimitChangedClampedToDueTerms() async {
        let terms = (1...5).map { Self.makeTerm(termText: "term\($0)", translation: "trans\($0)") }

        let store = TestStore(
            initialState: LearningSetupFeature.State(termsToLearn: terms, userLimit: 5)
        ) {
            LearningSetupFeature()
        }
        store.exhaustivity = .off

        await store.send(.limitChanged(10))
        #expect(store.state.userLimit == 5)

        await store.send(.limitChanged(0))
        #expect(store.state.userLimit == 1)

        await store.send(.limitChanged(3))
        #expect(store.state.userLimit == 3)
    }

    @Test
    func testStartLearningTappedSkipsMultipleChoiceWhenLessThanFourTerms() async {
        let term1 = Self.makeTerm(termText: "apple", translation: "яблуко")
        let term2 = Self.makeTerm(termText: "banana", translation: "банан")

        let store = TestStore(
            initialState: LearningSetupFeature.State(
                termsToLearn: [term1, term2],
                userLimit: 2
            )
        ) {
            LearningSetupFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.startLearningTapped)

        #expect(store.state.session != nil)
        #expect(store.state.session?.exercises.count == 6)
        #expect(store.state.session?.exercises.contains(where: { $0.type == .multipleChoice }) == false)
    }

    @Test
    func testStartLearningTappedPutsMultipleChoiceFirstWhenFourOrMoreTerms() async {
        let terms = (1...4).map { Self.makeTerm(termText: "term\($0)", translation: "trans\($0)") }

        let store = TestStore(
            initialState: LearningSetupFeature.State(
                termsToLearn: terms,
                userLimit: 4
            )
        ) {
            LearningSetupFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.startLearningTapped)

        #expect(store.state.session != nil)
        #expect(store.state.session?.exercises.count == 16)
        #expect(store.state.session?.exercises.first?.type == .multipleChoice)
    }
}
