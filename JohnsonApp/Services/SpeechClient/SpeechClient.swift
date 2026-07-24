//
//  SpeechClient.swift
//  JohnsonApp
//

import AVFoundation
import ComposableArchitecture
import Foundation


struct SpeechClient {
    var speak: @Sendable (String, Language) async -> Void
    var stop: @Sendable () async -> Void
}


@MainActor
private final class SpeechSynthesizerWrapper {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, language: Language) {
        configureAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(language: language.bcp47) {
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = fallbackVoice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[SpeechClient] Failed to configure AVAudioSession: \(error)")
        }
    }
}



extension SpeechClient: DependencyKey {

    static let liveValue: Self = {
        let wrapper = SpeechSynthesizerWrapper()
        return Self(
            speak: { text, language in
                await wrapper.speak(text: text, language: language)
            },
            stop: {
                await wrapper.stop()
            }
        )
    }()

    static let testValue = Self(
        speak: { _, _ in },
        stop: {}
    )
}


extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}
