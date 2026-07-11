//
//  DictionaryView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct DictionaryView: View {
    @Bindable var store: StoreOf<DictionaryFeature>
    
    init(store: StoreOf<DictionaryFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Словник")
                    .font(.title)
                searchBar()
                Picker("Статус", selection: $store.statusFilter.sending(\.statusFilterChanged)) {
                    ForEach(DictionaryFeature.StatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .background(Color(.systemBackground))
                
                if store.isLoading && store.terms.isEmpty {
                    Spacer()
                    ProgressView("Завантаження словника...")
                        .tint(.accentColor)
                    Spacer()
                } else if store.terms.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack (alignment: .leading, spacing: 20){
                            ForEach(store.terms) { term in
                                termCardView(for: term)
                                    .listRowSeparator(.hidden)
                                    .onTapGesture {
                                        store.send(.termTapped(term))
                                    }
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
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    private func searchBar() -> some View {
        HStack(){
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
    
    private func termCardView(for term: Term) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(term.termText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(term.translation)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                statusBadge(for: term.status)
            }
            
            if let hint = term.hint, !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider()
                    .padding(.top, 4)
                
                HStack(spacing: 4) {
                    Image(systemName: "pencil.line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hint)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
        )
    }
    
    private func statusBadge(for status: LearningStatus) -> some View {
        let (text, textColor, backgroundColor) = badgeProperties(for: status)
        
        return Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(textColor)
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
                .foregroundColor(.secondary)
            
            Text("Додайте слова, щоб розпочати вивчення та тренування.")
                .font(.title2)
                .foregroundColor(.secondary)
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
