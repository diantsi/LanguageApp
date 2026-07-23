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
        case parseCompleted(ImportResult, [UUID])
        case removeTermTapped(UUID)
        case saveButtonTapped
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
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date
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
                return .run { [importClient, persistenceClient] send in
                    let result = importClient.parse(text)
                    var duplicateIDs: [UUID] = []
                    var seenTerms = Set<String>()
                    
                    for term in result.validTerms {
                        let normText = term.termText
                            .trimmingCharacters(in: .whitespaces)
                            .lowercased()
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        let normTranslation = term.translation
                            .trimmingCharacters(in: .whitespaces)
                            .lowercased()
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        let normalizedKey = "\(normText)||\(normTranslation)"
                        
                        if seenTerms.contains(normalizedKey) {
                            duplicateIDs.append(term.id)
                        } else {
                            seenTerms.insert(normalizedKey)
                            do {
                                let isDuplicate = try await persistenceClient.termExists(term.termText, term.translation)
                                if isDuplicate {
                                    duplicateIDs.append(term.id)
                                }
                            } catch {}
                        }
                    }
                    await send(.parseCompleted(result, duplicateIDs))
                }
                
            case let .parseCompleted(result, duplicateIDs):
                state.parsedTerms = result.validTerms
                state.invalidLines = result.invalidLines
                state.duplicateIDs = Set(duplicateIDs)
                state.isParsed = true
                state.isLoading = false
                return .none
                
            case let .removeTermTapped(id):
                state.parsedTerms.removeAll { $0.id == id }
                state.duplicateIDs.remove(id)
                return .none
                
            case .saveButtonTapped:
                guard !state.parsedTerms.isEmpty else { return .none }
                let toSave = state.parsedTerms.filter { !state.duplicateIDs.contains($0.id) }
                guard !toSave.isEmpty else {
                    state.isLoading = false
                    return .none
                }
                state.isLoading = true
                let termLanguage = state.termLanguage
                let translationLanguage = state.translationLanguage
                let generateUUID = self.uuid
                let dateNow = self.date.now
                return .run { [toSave] send in
                    do {
                        let terms = toSave.map { parsed in
                            Term(
                                id: generateUUID(),
                                termText: parsed.termText,
                                translation: parsed.translation,
                                hint: parsed.hint,
                                termLanguage: termLanguage,
                                translationLanguage: translationLanguage,
                                createdAt: dateNow,
                                updatedAt: dateNow,
                                status: .new
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
}
