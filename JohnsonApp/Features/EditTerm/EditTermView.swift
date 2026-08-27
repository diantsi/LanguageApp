//
//  EditTermView.swift
//  JohnsonApp
//
//

import ComposableArchitecture
import SwiftUI

struct EditTermView: View {
    @Bindable var store: StoreOf<EditTermFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Термін")) {
                    TextField("Введіть термін", text: $store.termText.sending(\.termTextChanged))
                        .disabled(!store.isEditing)
                }

                Section(header: Text("Переклад")) {
                    TextField("Введіть переклад", text: $store.translation.sending(\.translationChanged))
                        .disabled(!store.isEditing)
                }

                Section(header: Text("Підказка (необов'язково)")) {
                    TextField("Введіть підказку", text: $store.hint.sending(\.hintChanged))
                        .disabled(!store.isEditing)
                }

                if !store.isEditing {
                    Section {
                        Button(role: .destructive) {
                            store.send(.deleteButtonTapped)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Видалити термін")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(store.isEditing ? "Редагування" : "Деталі терміна")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.isEditing {
                        Button("Скасувати") {
                            store.send(.closeButtonTapped)
                        }
                        .foregroundStyle(AppTheme.sageGreen)
                    } else {
                        Button("Закрити") {
                            store.send(.closeButtonTapped)
                        }
                        .foregroundStyle(AppTheme.sageGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.isEditing {
                        if store.isLoading {
                            ProgressView()
                        } else {
                            Button("Зберегти") {
                                store.send(.saveButtonTapped)
                            }
                            .fontWeight(.bold)
                            .foregroundStyle(store.canSave ? AppTheme.accentBlue : Color.gray)
                            .disabled(!store.canSave)
                        }
                    } else {
                        Button("Редагувати") {
                            store.send(.editButtonTapped)
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.accentBlue)
                    }
                }
            }
            .tint(AppTheme.sageGreen)
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    EditTermView(
        store: Store(
            initialState: EditTermFeature.State(
                term: Term(
                    id: UUID(),
                    termText: "apple",
                    translation: "яблуко",
                    hint: "fruit",
                    termLanguage: .english,
                    translationLanguage: .ukrainian,
                    createdAt: Date(),
                    updatedAt: Date(),
                    status: .new
                )
            )
        ) {
            EditTermFeature()
        }
    )
}


