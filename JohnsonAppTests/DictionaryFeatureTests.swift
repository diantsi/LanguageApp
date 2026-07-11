//
//  DictionaryFeatureTests.swift
//  JohnsonApp
//

import ComposableArchitecture
import XCTest
@testable import JohnsonApp

@MainActor
final class DictionaryFeatureTests: XCTestCase {

    func testOnAppearFetchesTerms() async throws {
        let term1 = Term(termText: "apple", translation: "яблуко", termLanguage: .english, translationLanguage: .ukrainian)
        let term2 = Term(termText: "banana", translation: "банан", termLanguage: .english, translationLanguage: .ukrainian)
        let mockTerms = [term1, term2]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _ in mockTerms }
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
        let term1 = Term(termText: "apple", translation: "яблуко", termLanguage: .english, translationLanguage: .ukrainian)
        let mockTerms = [term1]

        let clock = TestClock()

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, _, _ in mockTerms }
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
        let term1 = Term(termText: "apple", translation: "яблуко", termLanguage: .english, translationLanguage: .ukrainian) // .new

        let term2 = Term(termText: "cherry", translation: "вишня", termLanguage: .english, translationLanguage: .ukrainian) // .learning
        term2.learningProgress?.lastReviewDate = Date()
        term2.learningProgress?.stability = 10.0

        let term3 = Term(termText: "date", translation: "фінік", termLanguage: .english, translationLanguage: .ukrainian) // .mastered
        term3.learningProgress?.lastReviewDate = Date()
        term3.learningProgress?.stability = 400.0

        let allTerms = [term1, term2, term3]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            // Фільтрацію тепер робить mock-база
            $0.persistenceClient.fetchTerms = { _, status, _, _ in
                guard let status else { return allTerms }
                return allTerms.filter { $0.status == status }
            }
        }

        // 1. Початкове завантаження (всі статуси)
        await store.send(.onAppear) {
            $0.isLoading = true
        }
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
        await store.receive(.fetchTermsSuccess([term1], isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = [term1]
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
        await store.receive(.fetchTermsSuccess([term2], isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = [term2]
            $0.hasMore = false
        }
    }

    func testLoadMoreTermsPagination() async throws {
        // Створюємо 40 термінів для заповнення першої сторінки
        let firstPage = (1...40).map { i in
            Term(termText: "term\(i)", translation: "translation\(i)", termLanguage: .english, translationLanguage: .ukrainian)
        }
        let secondPage = [
            Term(termText: "term41", translation: "translation41", termLanguage: .english, translationLanguage: .ukrainian)
        ]

        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _, _, limit, offset in
                if offset == 0 {
                    return firstPage
                } else {
                    return secondPage
                }
            }
        }

        // Завантаження першої сторінки
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(firstPage, isLoadMore: false)) {
            $0.isLoading = false
            $0.terms = firstPage
            $0.hasMore = true // Рівно 40 елементів, тому очікуємо ще
        }

        // Завантаження другої сторінки
        await store.send(.loadMoreTerms) {
            $0.isLoading = true
        }
        await store.receive(.fetchTermsSuccess(secondPage, isLoadMore: true)) {
            $0.isLoading = false
            $0.terms = firstPage + secondPage
            $0.hasMore = false // 1 елемент (< 40), більше немає
        }
    }
}
