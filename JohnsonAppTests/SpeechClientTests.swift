//
//  SpeechClientTests.swift
//  JohnsonAppTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import JohnsonApp

struct SpeechClientTests {

    // MARK: - testValue

    @Test
    func testTestValueSpeakIsNoOp() async {
        // testValue should not throw or crash
        await SpeechClient.testValue.speak("hello", .english)
    }

    @Test
    func testTestValueStopIsNoOp() async {
        // testValue should not throw or crash
        await SpeechClient.testValue.stop()
    }

    // MARK: - Dependency injection

    @Test
    func testSpeakIsCalledWithCorrectArguments() async {
        var receivedText: String?
        var receivedLanguage: Language?

        let client = SpeechClient(
            speak: { text, language in
                receivedText = text
                receivedLanguage = language
            },
            stop: {}
        )

        await client.speak("take off", .english)

        #expect(receivedText == "take off")
        #expect(receivedLanguage == .english)
    }

    @Test
    func testStopIsCalled() async {
        var stopCalled = false

        let client = SpeechClient(
            speak: { _, _ in },
            stop: { stopCalled = true }
        )

        await client.stop()

        #expect(stopCalled)
    }

    @Test
    func testSpeakWithUkrainianLanguage() async {
        var receivedLanguage: Language?

        let client = SpeechClient(
            speak: { _, language in receivedLanguage = language },
            stop: {}
        )

        await client.speak("яблуко", .ukrainian)

        #expect(receivedLanguage == .ukrainian)
    }
}
