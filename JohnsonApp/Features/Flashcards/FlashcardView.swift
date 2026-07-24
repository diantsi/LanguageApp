//
//  FlashcardView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct FlashcardView: View {
    let store: StoreOf<FlashcardFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.isLoading {
                    Spacer()
                    ProgressView("Завантаження карток...")
                        .tint(.accentColor)
                    Spacer()
                } else if store.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    cardSessionView
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("Картки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    firstSidePicker
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }


    private var cardSessionView: some View {
        VStack(spacing: 20) {
            
            Text(store.counter)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)

            Spacer()

            if let sides = store.currentCardSides {
                CardView(
                    sides: sides,
                    isFlipped: store.isFlipped
                )
                .onTapGesture {
                    store.send(.flipCard)
                }
            }

            Spacer()

            navigationButtons
                .padding(.bottom, 20)
        }
    }


    private var navigationButtons: some View {
        HStack(spacing: 24) {
            Button {
                store.send(.previousCard)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .frame(width: 50, height: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .disabled(!store.canGoPrevious)

            Button {
                store.send(.restartSession)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2.weight(.semibold))
                    .frame(width: 50, height: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }

            Button {
                store.send(.nextCard)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2.weight(.semibold))
                    .frame(width: 50, height: 50)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .disabled(!store.canGoNext)
        }
        .tint(.primary)
    }


    private var firstSidePicker: some View {
        Menu {
            ForEach(FlashcardFeature.FirstSide.allCases, id: \.self) { side in
                Button {
                    store.send(.firstSideChanged(side))
                } label: {
                    if store.firstSide == side {
                        Label(side.title, systemImage: "checkmark")
                    } else {
                        Text(side.title)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.body)
        }
    }


    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Додайте слова до словника, щоб почати вивчення з картками.")
                .font(.title2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                store.send(.goToDictionaryTapped)
            } label: {
                Label("Перейти до словника", systemImage: "character.book.closed")
            }
            .padding(.top, 8)
        }
        .padding()
    }
}


private struct CardView: View {
    let sides: FlashcardFeature.CardSides
    let isFlipped: Bool

    var body: some View {
        ZStack {
            cardFace(sides.front)
            cardFace(sides.back)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }

    private func cardFace(_ face: FlashcardFeature.CardFace) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            VStack(spacing: 12) {
                Text(face.text)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let hint = face.hint, !hint.isEmpty {
                    Text("(\(hint))")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Text(face.label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }
}



#Preview {
    FlashcardView(
        store: Store(initialState: FlashcardFeature.State()) {
            FlashcardFeature()
        } withDependencies: {
            $0.persistenceClient = .previewValue
        }
    )
}
