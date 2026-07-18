//
//  DictionaryView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct DictionaryView: View {
    @Bindable var store: StoreOf<DictionaryFeature>
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Словник")
                    .font(.title)
                searchBar()
                Picker("Статус", selection: $store.statusFilter.sending(\.statusFilterChanged)) {
                    ForEach(DictionaryFeature.StatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .background(Color(.systemBackground))
                
                if store.isLoading && store.terms.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView("Завантаження словника...")
                            .tint(.accentColor)
                        Spacer()
                    }
                    Spacer()
                } else if store.terms.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack (alignment: .leading, spacing: 20){
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
                }
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .sheet(item: $store.scope(state: \.addTerms, action: \.addTerms)) { addTermsStore in
                AddTermsView(store: addTermsStore)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
    
    private func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("пошук термів", text: $store.searchQuery.sending(\.searchQueryChanged))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(height: 50)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1)
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
                .blue,
                Color.blue.opacity(0.12)
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
                .green,
                Color.green.opacity(0.12)
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Додайте слова, щоб розпочати вивчення та тренування.")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Button {
                store.send(.addButtonTapped)
            } label: {
                Label("Додати слова", systemImage: "plus")
            }
            .padding(.horizontal, 32)
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
