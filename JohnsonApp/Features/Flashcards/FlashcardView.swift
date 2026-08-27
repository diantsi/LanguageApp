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
                        .tint(AppTheme.sageGreen)
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
            .background(AppTheme.backgroundColor)
            .safeAreaInset(edge: .top) {
                HeaderBannerView(title: "картки", imageName: "studycat") {
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }


    private var cardSessionView: some View {
        VStack(spacing: 20) {
            
            HStack {
                Text(store.counter)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.sageGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.sageGreen.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.top, 16)

            Spacer()
            
            Button {
                store.send(.voiceButtonTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Озвучити")
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.accentBlue.opacity(0.12))
                .foregroundStyle(AppTheme.accentBlue)
                .clipShape(Capsule())
            }

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
                    .frame(width: 54, height: 54)
                    .background(AppTheme.cardBackgroundColor)
                    .foregroundStyle(store.canGoPrevious ? AppTheme.accentBlue : Color.gray.opacity(0.4))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(store.canGoPrevious ? AppTheme.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1))
            }
            .disabled(!store.canGoPrevious)

            Button {
                store.send(.restartSession)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(AppTheme.cardBackgroundColor)
                    .foregroundStyle(AppTheme.sageGreen)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.sageGreen.opacity(0.3), lineWidth: 1))
            }
            
            Button {
                store.send(.firstSideChanged)
            } label: {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title2.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(AppTheme.cardBackgroundColor)
                    .foregroundStyle(AppTheme.sageGreen)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.sageGreen.opacity(0.3), lineWidth: 1))
            }
            
            Button {
                store.send(.nextCard)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(AppTheme.cardBackgroundColor)
                    .foregroundStyle(store.canGoNext ? AppTheme.accentBlue : Color.gray.opacity(0.4))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(store.canGoNext ? AppTheme.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1))
            }
            .disabled(!store.canGoNext)
            
        }
    }


    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.sageGreen.opacity(0.7))

            Text("Додайте слова до словника, щоб почати вивчення з картками.")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                store.send(.goToDictionaryTapped)
            } label: {
                Label("Перейти до словника", systemImage: "character.book.closed")
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
            VStack(spacing: 14) {
                Text(face.text)
                    .font(.title2.weight(.bold))
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
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.sageGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.sageGreen.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .appCardStyle(cornerRadius: 20, borderColor: AppTheme.sageGreen.opacity(0.4), borderWidth: 1.5)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
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
