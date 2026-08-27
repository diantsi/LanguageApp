//
//  DictionaryView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct DictionaryView: View {
    @Bindable var store: StoreOf<DictionaryFeature>
    @FocusState private var isSearchFocused: Bool

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                searchBar()
                
                Picker("Статус", selection: $store.statusFilter.sending(\.statusFilterChanged)) {
                    ForEach(DictionaryFeature.StatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: store.statusFilter) {
                    isSearchFocused = false
                }

                if store.isLoading && store.terms.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView("Завантаження словника...")
                            .tint(AppTheme.sageGreen)
                        Spacer()
                    }
                    Spacer()
                } else if store.terms.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(store.terms) { term in
                                TermCardView(
                                    termText: term.termText,
                                    translation: term.translation,
                                    hint: term.hint,
                                    onDelete: { store.send(.deleteButtonTapped(term)) }
                                ) {
                                    statusBadge(for: term.status)
                                }
                                .onTapGesture {
                                    isSearchFocused = false
                                    store.send(.termTapped(term))
                                }
                            }

                            if store.hasMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .onAppear {
                                            store.send(.loadMoreTerms)
                                        }
                                    Spacer()
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .background(AppTheme.backgroundColor)
            .safeAreaInset(edge: .top) {
                headerBanner
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
            .onAppear {
                store.send(.onAppear)
            }
            .sheet(item: $store.scope(state: \.addTerms, action: \.addTerms)) { addTermsStore in
                AddTermsView(store: addTermsStore)
            }
            .sheet(item: $store.scope(state: \.editTerm, action: \.editTerm)) { editStore in
                EditTermView(store: editStore)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }

    private var headerBanner: some View {
        HeaderBannerView(title: "словник", imageName: "hellocat") {
            Button {
                isSearchFocused = false
                store.send(.addButtonTapped)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .padding(.trailing, 8)
            }
        }
    }

    private func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isSearchFocused ? AppTheme.sageGreen : .secondary)
            TextField("пошук термів", text: $store.searchQuery.sending(\.searchQueryChanged))
                .focused($isSearchFocused)

            if !store.searchQuery.isEmpty {
                Button {
                    store.send(.searchQueryChanged(""))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 48)
        .background(AppTheme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSearchFocused ? AppTheme.sageGreen : Color.gray.opacity(0.2), lineWidth: isSearchFocused ? 1.5 : 1)
        )
    }

    private func statusBadge(for status: LearningStatus) -> some View {
        let (text, textColor, backgroundColor) = badgeProperties(for: status)

        return Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private func badgeProperties(for status: LearningStatus) -> (String, Color, Color) {
        switch status {
        case .new:
            return (
                status.localizedName.uppercased(),
                AppTheme.accentBlue,
                AppTheme.accentBlue.opacity(0.12)
            )
        case .learning:
            return (
                status.localizedName.uppercased(),
                .orange,
                Color.orange.opacity(0.12)
            )
        case .mastered:
            return (
                status.localizedName.uppercased(),
                AppTheme.sageGreen,
                AppTheme.sageGreen.opacity(0.15)
            )
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.sageGreen.opacity(0.7))

            Text("Додайте слова, щоб розпочати вивчення та тренування.")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                store.send(.addButtonTapped)
            } label: {
                Label("Додати слова", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding()
        .multilineTextAlignment(.center)
    }
}

#Preview {
    DictionaryView(
        store: Store(initialState: DictionaryFeature.State()) {
            DictionaryFeature()
        }
    )
}
