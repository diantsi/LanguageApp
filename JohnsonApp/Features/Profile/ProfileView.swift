//
//  ProfileView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .center, spacing: 8) {
                        Image("caticon")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.sageGreen, lineWidth: 2))
                        
                        HStack(spacing: 4) {
                            Text(store.username)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(AppTheme.sageGreen)
                        }
                    }
                    
                    Spacer()

                    VStack(alignment: .center, spacing: 15) {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 42))
                            Text("\(store.userStreak)")
                                .font(.system(size: 42, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.sageGreen)
                        }
                        Text("днів підряд")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    
                }
                .padding(.horizontal, 50)

                if let active = store.activeSession {
                    activeSession(active: active)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Ваші сесії")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))

                        Spacer()

                        Button {
                            store.send(.addSessionButtonTapped)
                        } label: {
                            Label(
                                "Додати сесію",
                                systemImage: "plus.circle.fill"
                            )
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accentBlue)
                        }
                    }

                    if store.sessions.isEmpty {
                        Text("Сесій немає")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.sessions) { session in
                                sessionRow(session)
                            }
                        }
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.backgroundColor)
        .safeAreaInset(edge: .top) {
            HeaderBannerView(title: "привіт, \(store.username)", imageName: "hellocat")
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.addSession, action: \.addSession)) { store in
            CreateSessionView(store: store)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }


    private func activeSession(active: LanguageSession) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        "Активна сесія",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.sageGreen)
                    .textCase(.uppercase)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(active.name)
                        .font(.system(size: 18, weight: .bold))

                    Text("\(active.termLanguage.displayName) → \(active.translationLanguage.displayName)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 2) {
                Text("100")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("термів")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.accentBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: 16, borderColor: AppTheme.sageGreen.opacity(0.4), borderWidth: 1.5)
    }

    private func sessionRow(_ session: LanguageSession) -> some View {
        let isActive = (session.id == store.activeSessionId)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.name)
                        .font(.system(size: 15, weight: .bold))
                    if isActive {
                        Text("АКТИВНА")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.sageGreen.opacity(0.15))
                            .foregroundStyle(AppTheme.sageGreen)
                            .clipShape(Capsule())
                    }
                }

                Text("\(session.termLanguage.displayName) → \(session.translationLanguage.displayName)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                store.send(.deleteSessionButtonTapped(session))
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .appCardStyle(
            cornerRadius: 12,
            borderColor: isActive ? AppTheme.sageGreen.opacity(0.5) : Color.gray.opacity(0.15),
            borderWidth: isActive ? 1.5 : 1
        )
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.sessionTapped(session))
        }
    }
}

#Preview {
    ProfileView(
        store: Store(
            initialState: ProfileFeature.State(
                sessions: [
                    LanguageSession.mock,
                    LanguageSession(
                        id: UUID(),
                        name: "Польська для роботи",
                        termLanguage: .polish,
                        translationLanguage: .ukrainian,
                        createdAt: Date()
                    ),
                ],
                activeSessionId: LanguageSession.mock.id
            )
        ) {
            ProfileFeature()
        } withDependencies: {
            $0.persistenceClient = .previewValue
        }
    )
}
