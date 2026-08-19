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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                HStack(alignment: .center, spacing: 20) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.gray)
                        .padding(20)
                        .frame(width: 90, height: 90)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.gray.opacity(0.5), lineWidth: 3)
                        }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.username)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 4) {
                            Text("\(store.userStreak) дн. поспіль")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("🔥")
                        }
                    }
                    Spacer()
                }

                if let active = store.activeSession {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Активна сесія", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                                .textCase(.uppercase)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(active.name)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("\(active.termLanguage.displayName) → \(active.translationLanguage.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Створено: \(Self.dateFormatter.string(from: active.createdAt))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.green.opacity(0.3), lineWidth: 1.5)
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ваші сесії")
                            .font(.headline)

                        Spacer()

                        Button {
                            store.send(.addSessionButtonTapped)
                        } label: {
                            Label("Додати сесію", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
        .sheet(item: $store.scope(state: \.addSession, action: \.addSession)) { store in
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(height: 100, alignment: .bottom)
        .background(Color(red: 0.38, green: 0.53, blue: 0.35))
        .overlay(alignment: .trailing) {
            Image("cat")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .offset(x: 10, y: 15)
        }
        .clipped()
    }


    private func sessionRow(_ session: LanguageSession) -> some View {
        let isActive = (session.id == store.activeSessionId)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.name)
                        .font(.body)
                        .fontWeight(isActive ? .bold : .medium)
                        .foregroundStyle(isActive ? .primary : .secondary)

                    if isActive {
                        Text("Активна")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                Text("\(session.termLanguage.displayName) → \(session.translationLanguage.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button {
                    store.send(.sessionTapped(session))
                } label: {
                    Text("Вибрати")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

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
                .strokeBorder(isActive ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
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
                    )
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
