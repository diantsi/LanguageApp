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
            $0.persistenceClient.fetchTerms = { _ in mockTerms }
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(.fetchTerms)
        
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = mockTerms
        }
    }
    
    func testSearchQueryChangedWithDebounce() async throws {
        let term1 = Term(termText: "apple", translation: "яблуко", termLanguage: .english, translationLanguage: .ukrainian)
        let mockTerms = [term1]
        
        let clock = TestClock()
        
        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _ in mockTerms }
            $0.continuousClock = clock
        }
        
        await store.send(.searchQueryChanged("ap")) {
            $0.searchQuery = "ap"
            $0.isLoading = true
        }
        
        // Перевіряємо, що після зміни тексту запит не відразу відправляється (через debounce)
        await clock.advance(by: .milliseconds(150))
        
        // Вводимо ще один символ
        await store.send(.searchQueryChanged("app")) {
            $0.searchQuery = "app"
        }
        
        // Просуваємо час вперед на 300мс — тепер має спрацювати пошук
        await clock.advance(by: .milliseconds(300))
        
        await store.receive(.fetchTerms)
        
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = mockTerms
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
        
        let mockTerms = [term1, term2, term3]
        
        let store = TestStore(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        } withDependencies: {
            $0.persistenceClient.fetchTerms = { _ in mockTerms }
        }
        
        // 1. Початкове завантаження (всі статуси)
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = mockTerms
        }
        
        // 2. Зміна фільтру на "Нові"
        await store.send(.statusFilterChanged(.new)) {
            $0.statusFilter = .new
            $0.isLoading = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = [term1]
        }
        
        // 3. Зміна фільтру на "В процесі"
        await store.send(.statusFilterChanged(.learning)) {
            $0.statusFilter = .learning
            $0.isLoading = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = [term2]
        }
        
        // 4. Зміна фільтру на "Засвоєні"
        await store.send(.statusFilterChanged(.mastered)) {
            $0.statusFilter = .mastered
            $0.isLoading = true
        }
        await store.receive(.fetchTerms)
        await store.receive(.fetchTermsSuccess(mockTerms)) {
            $0.isLoading = false
            $0.terms = [term3]
        }
    }
}
