//
//  DictionaryFeatureTests.swift
//  JohnsonApp
//

import ComposableArchitecture
import XCTest
@testable import JohnsonApp

@MainActor
final class DictionaryFeatureTests: XCTestCase {

    // MARK: - Helpers

    private func makeTerm(
        termText: String,
        translation: String,
        status: LearningStatus = .new
    ) -> Term {
        Term(
            id: UUID(),
            termText: termText,
            translation: translation,
            hint: nil,
            termLanguage: .english,
            translationLanguage: .ukrainian,
            createdAt: Date(),
            updatedAt: Date(),
            status: status
        )
    }

    // MARK: - Tests

    func testOnAppearFetchesTerms() async throws {
        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let term2 = makeTerm(termText: "banana", translation: "банан")
        let mockTerms = [term1, term2]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, _ in mockTerms }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(.fetchTerms)

        // mockTerms.count менше за pageSize (40), тому hasMore стане false
        await store.receive(.fetchTermsSuccess(mockTerms, isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = mockTerms
            $0.hasMore = false
        }
    }

    func testSearchQueryChangedWithDebounce() async throws {
        let term1 = makeTerm(termText: "apple", translation: "яблуко")
        let mockTerms = [term1]

        let clock = TestClock()

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, _ in mockTerms }
            $0.continuousClock = clock
        }

        await store.send(.searchQueryChanged("ap")) {
            $0.searchQuery = "ap"
            $0.isLoading = true
        }

        await clock.advance(by: .milliseconds(150))

        await store.send(.searchQueryChanged("app")) {
            $0.searchQuery = "app"
        }

        await clock.advance(by: .milliseconds(300))

        await store.receive(.fetchTerms)

        await store.receive(.fetchTermsSuccess(mockTerms, isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = mockTerms
            $0.hasMore = false
        }
    }

    func testStatusFilterChangedFiltersTerms() async throws {
        let newTerm     = makeTerm(termText: "apple", translation: "яблуко", status: .new)
        let learningTerm = makeTerm(termText: "cherry", translation: "вишня", status: .learning)
        let masteredTerm = makeTerm(termText: "date", translation: "фінік", status: .mastered)
        let allTerms = [newTerm, learningTerm, masteredTerm]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, status, _, _ in
                guard let status else { return allTerms }
                return allTerms.filter { $0.status == status }
            }
        }

        // 1. Початкове завантаження (всі статуси)
        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(allTerms, isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = allTerms
            $0.hasMore = false
        }

        // 2. Зміна фільтру на "Нові"
        await store.send(.statusFilterChanged(.new)) {
            $0.statusFilter = .new
            $0.isLoading = true
            $0.terms = []
            $0.hasMore = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess([newTerm], isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = [newTerm]
            $0.hasMore = false
        }

        // 3. Зміна фільтру на "В процесі"
        await store.send(.statusFilterChanged(.learning)) {
            $0.statusFilter = .learning
            $0.isLoading = true
            $0.terms = []
            $0.hasMore = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess([learningTerm], isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = [learningTerm]
            $0.hasMore = false
        }
    }

    func testLoadMoreTermsPagination() async throws {
        let firstPage = (1...40).map { i in
            makeTerm(termText: "term\(i)", translation: "translation\(i)")
        }
        let secondPage = [makeTerm(termText: "term41", translation: "translation41")]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _, offset in
                offset == 0 ? firstPage : secondPage
            }
        }

        // Завантаження першої сторінки
        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(firstPage, isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = firstPage
            $0.hasMore = true // Рівно 40 елементів, тому очікуємо ще
        }

        // Завантаження другої сторінки
        await store.send(.loadMoreTerms) { $0.isLoading = true }
        await store.receive(.fetchTermsSuccess(secondPage, isLoadMore: true)) {
            $0.isLoading = false
            $0.terms = firstPage + secondPage
            $0.hasMore = false // 1 елемент (< 40), більше немає
        }
    }
}
