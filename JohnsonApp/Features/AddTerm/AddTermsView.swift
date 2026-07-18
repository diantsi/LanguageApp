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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Додати слова")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") {
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    } else {
                        Button("Зберегти") {
                            store.send(.saveButtonTapped)
                        }
                        .fontWeight(.semibold)
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .background(store.inputText.isEmpty ? Color.accentColor.opacity(0.4) : Color.accentColor)
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
                color: .green
            )
            if store.hasDuplicates {
                statBadge(
                    count: store.duplicateIDs.count,
                    label: "дублікатів",
                    color: .orange
                )
            }
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
            Text("Деякі терміни вже є у словнику і будуть пропущені.")
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
                ) {
                    if store.duplicateIDs.contains(term.id) {
                        Label("ДУБЛІКАТ", systemImage: "doc.on.doc.fill")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundStyle(.orange)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .opacity(store.duplicateIDs.contains(term.id) ? 0.45 : 1)
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
