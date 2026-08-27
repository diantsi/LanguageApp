//
//  AddTermsView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct AddTermsView: View {
    @Bindable var store: StoreOf<AddTermsFeature>
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    formatHintView
                    textEditorSection
                    parseButton

                    if store.isParsed {
                        statsRow
                        if store.hasDuplicates {
                            duplicatesBanner
                        }
                        if !store.invalidLines.isEmpty {
                            invalidLinesBanner
                        }
                        parsedTermsList
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundColor)
            .navigationTitle("Додати слова")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundStyle(AppTheme.sageGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                }
            }
        }
    }

    // MARK: - Format hint

    private var formatHintView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Формат введення", systemImage: "info.circle")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("term - translation")
                Text("term - translation (hint)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle(cornerRadius: 10, borderColor: AppTheme.sageGreen.opacity(0.2), borderWidth: 1)
        }
    }

    // MARK: - Text editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Терміни")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $store.inputText.sending(\.inputTextChanged))
                    .frame(minHeight: 160)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isEditorFocused ? AppTheme.sageGreen : AppTheme.sageGreen.opacity(0.25), lineWidth: isEditorFocused ? 1.5 : 1)
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isEditorFocused)

                if store.inputText.isEmpty {
                    Text("apple - яблуко\ndate - фінік (як побачення)")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Parse button

    private var parseButton: some View {
        Button {
            isEditorFocused = false
            store.send(.parseButtonTapped)
        } label: {
            HStack {
                Spacer()
                if store.isLoading && !store.isParsed {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Створити карточки", systemImage: "wand.and.stars")
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(store.inputText.isEmpty ? AppTheme.accentBlue.opacity(0.4) : AppTheme.accentBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(store.inputText.isEmpty || store.isLoading)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBadge(
                count: store.parsedTerms.count,
                label: "термінів",
                color: AppTheme.sageGreen
            )
            if !store.invalidLines.isEmpty {
                statBadge(
                    count: store.invalidLines.count,
                    label: "невалідних",
                    color: .red
                )
            }
            Spacer()
        }
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .fontWeight(.bold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Banners

    private var duplicatesBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.orange)
            Text("Деякі терміни вже є у словнику і не будуть додані.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var invalidLinesBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text("\(store.invalidLines.count) рядків не вдалось розібрати")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            ForEach(store.invalidLines, id: \.lineNumber) { line in
                Text("Рядок \(line.lineNumber): \(line.content)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Parsed terms list

    private var parsedTermsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Попередній перегляд")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(store.parsedTerms) { term in
                TermCardView(
                    termText: term.termText,
                    translation: term.translation,
                    hint: term.hint,
                    onDelete: { store.send(.removeTermTapped(term.id)) }
                )
            }
        }
    }
}

#Preview {
    AddTermsView(
        store: Store(initialState: AddTermsFeature.State()) {
            AddTermsFeature()
        }
    )
}
