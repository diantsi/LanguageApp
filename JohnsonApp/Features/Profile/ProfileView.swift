//
//  ProfileView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    private let greencolor : Color = Color(red: 0.4, green: 0.57, blue: 0.34)
    private let bluecolor: Color = Color(red: 0.2, green: 0.38, blue: 0.77)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                HStack(alignment: .bottom, spacing: 20) {
                    VStack(
                        alignment: .center,
                        spacing: 10
                    ) {
                        Image("caticon")
                            .resizable()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                        HStack {
                            Text(store.username)
                                .font(
                                    .system(size: 20, weight: .regular)
                                        .monospacedDigit()
                                )
                            Image(systemName: "pencil")
                        }
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 11) {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(
                                    .system(size: 60, weight: .regular)
                                        .monospacedDigit()
                                )
                            Text("\(store.userStreak)")
                                .font(
                                    .system(size: 60, weight: .regular)
                                        .monospacedDigit()
                                )
                        }
                        Text("днів підряд")
                            .font(
                                .system(size: 20, weight: .regular)
                                    .monospacedDigit()
                            )
                    }
                }
                .padding(.horizontal, 50)

                if let active = store.activeSession {
                    activeSession(active: active)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ваші сесії")
                            .font(.system(size: 20, weight: .bold)
                                .monospacedDigit()
                                  )

                        Spacer()

                        Button {
                            store.send(.addSessionButtonTapped)
                        } label: {
                            Label(
                                "Додати сесію",
                                systemImage: "plus.circle.fill"
                            )
                            .font(.system(size: 15, weight: .bold)
                                .monospacedDigit())
                            .foregroundStyle(bluecolor)
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
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top) {
            headerBanner
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.addSession, action: \.addSession)) {
            store in
            CreateSessionView(store: store)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private var headerBanner: some View {
        HStack {
            Text("привіт, \(store.username)")
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
            Spacer()
            Image("cat2")
                .resizable()
                .frame(width: 125, height: 112)
        }.padding(.horizontal, 20)
            .background(
                greencolor
                    .ignoresSafeArea(edges: .top)
            )
    }
    
    private func activeSession(active: LanguageSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        "Активна сесія",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundStyle(greencolor)
                    .textCase(.uppercase)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(active.name)
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(
                        "\(active.termLanguage.displayName) → \(active.translationLanguage.displayName)"
                    )
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.gray)
                }
                
            }
            VStack{
                Text("100")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                Text("термів")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(10)
            .background(bluecolor)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    greencolor.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        
    }

    

    private func sessionRow(_ session: LanguageSession) -> some View {
        let isActive = (session.id == store.activeSessionId)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.name)
                        .font(.system(size: 15, weight: .bold))
                }

                Text(
                    "\(session.termLanguage.displayName) → \(session.translationLanguage.displayName)"
                )
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.gray)
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isActive ? greencolor.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
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
