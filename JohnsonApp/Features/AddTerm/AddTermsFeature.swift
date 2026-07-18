//
//  AddTermsFeature.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddTermsFeature {

    @ObservableState
    struct State: Equatable {
        var inputText: String = ""
        var parsedTerms: [ParsedTerm] = []
        var invalidLines: [InvalidLine] = []
        var duplicateIDs: Set<UUID> = []
        var isLoading: Bool = false
        var isParsed: Bool = false

        var termLanguage: Language = .english
        var translationLanguage: Language = .ukrainian

        var canSave: Bool { isParsed && !parsedTerms.isEmpty && !isLoading }
        var hasDuplicates: Bool { !duplicateIDs.isEmpty }

        init(
            inputText: String = "",
            parsedTerms: [ParsedTerm] = [],
            invalidLines: [InvalidLine] = [],
            duplicateIDs: Set<UUID> = [],
            isLoading: Bool = false,
            isParsed: Bool = false,
            termLanguage: Language = .english,
            translationLanguage: Language = .ukrainian
        ) {
            self.inputText = inputText
            self.parsedTerms = parsedTerms
            self.invalidLines = invalidLines
            self.duplicateIDs = duplicateIDs
            self.isLoading = isLoading
            self.isParsed = isParsed
            self.termLanguage = termLanguage
            self.translationLanguage = translationLanguage
        }
    }

    enum Action: Equatable {
        case inputTextChanged(String)
        case parseButtonTapped
        case parseCompleted(ImportResult)
        case removeTermTapped(UUID)
        case saveButtonTapped
        case duplicatesChecked([UUID])
        case saveCompleted
        case saveFailure(String)
        case cancelButtonTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case termsSaved
        }
    }

    @Dependency(\.importClient) var importClient
    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case let .inputTextChanged(text):
                state.inputText = text
                state.isParsed = false
                return .none

            case .parseButtonTapped:
                guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }
                let text = state.inputText
                state.isLoading = true
                return .run { [importClient] send in
                    let result = importClient.parse(text)
                    await send(.parseCompleted(result))
                }

            case let .parseCompleted(result):
                state.parsedTerms = result.validTerms
                state.invalidLines = result.invalidLines
                state.duplicateIDs = []
                state.isParsed = true
                state.isLoading = false
                return .none

            case let .removeTermTapped(id):
                state.parsedTerms.removeAll { $0.id == id }
                return .none

            case .saveButtonTapped:
                guard !state.parsedTerms.isEmpty else { return .none }
                let termsToCheck = state.parsedTerms
                state.isLoading = true
                return .run { send in
                    do {
                        let existing = try await persistenceClient.fetchTerms(nil, nil, nil, nil)
                        let ids = Self.findDuplicateIDs(among: termsToCheck, existing: existing)
                        await send(.duplicatesChecked(ids))
                    } catch {
                        await send(.saveFailure(error.localizedDescription))
                    }
                }

            case let .duplicatesChecked(ids):
                state.duplicateIDs = Set(ids)
                let toSave = state.parsedTerms.filter { !state.duplicateIDs.contains($0.id) }
                guard !toSave.isEmpty else {
                    state.isLoading = false
                    return .none
                }
                let termLanguage = state.termLanguage
                let translationLanguage = state.translationLanguage
                return .run { [toSave] send in
                    do {
                        let terms = toSave.map { parsed in
                            Term(
                                termText: parsed.termText,
                                translation: parsed.translation,
                                hint: parsed.hint,
                                termLanguage: termLanguage,
                                translationLanguage: translationLanguage
                            )
                        }
                        try await persistenceClient.addTerms(terms)
                        await send(.saveCompleted)
                    } catch {
                        await send(.saveFailure(error.localizedDescription))
                    }
                }

            case .saveCompleted:
                state.isLoading = false
                return .send(.delegate(.termsSaved))

            case .saveFailure:
                state.isLoading = false
                return .none

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Duplicate detection

    nonisolated static func findDuplicateIDs(among parsed: [ParsedTerm], existing: [Term]) -> [UUID] {
        parsed.compactMap { parsedTerm in
            let isDuplicate = existing.contains {
                normalize(parsedTerm.termText) == normalize($0.termText) &&
                normalize(parsedTerm.translation) == normalize($0.translation)
            }
            return isDuplicate ? parsedTerm.id : nil
        }
    }

    private nonisolated static func normalize(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
