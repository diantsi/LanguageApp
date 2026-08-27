//
//  CreateSessionView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI


struct CreateSessionView: View {
    @Bindable var store: StoreOf<CreateSessionFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section("Назва") {
                    TextField("напр. \"Англійська для подорожей\"",
                              text: $store.name.sending(\.nameChanged))
                        .submitLabel(.done)
                }

                Section("Мовна пара") {
                    Picker("Мова терміну", selection: $store.termLanguage.sending(\.termLanguageChanged)) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }

                    Picker("Мова перекладу", selection: $store.translationLanguage.sending(\.translationLanguageChanged)) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }

                if let error = store.validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        store.send(.submitTapped)
                    } label: {
                        HStack {
                            Spacer()
                            if store.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Створити сесію")
                                    .fontWeight(.bold)
                                    .foregroundStyle(store.canSubmit ? .white : .white.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!store.canSubmit)
                    .listRowBackground(store.canSubmit ? AppTheme.accentBlue : AppTheme.accentBlue.opacity(0.4))
                }
            }
            .tint(AppTheme.sageGreen)
            .navigationTitle("Нова сесія")
        }
    }
}


#Preview {
    CreateSessionView(
        store: Store(initialState: CreateSessionFeature.State()) {
            CreateSessionFeature()
        } withDependencies: {
            $0.persistenceClient = .previewValue
        }
    )
}
