//
//  LearningSummaryView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct LearningSummaryView: View {
    @Bindable var store: StoreOf<LearningSummaryFeature>

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow.gradient)

                Text("Сесію завершено!")
                    .font(.title.bold())

                Text("Чудова робота! Параметри вашої пам'яті оновлено за FSRS.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    statTile(title: "Пройдено термінів", value: "\(store.completedTermsCount)", icon: "square.stack.fill", color: .blue)
                    statTile(title: "Виконано вправ", value: "\(store.totalExercisesCount)", icon: "checkmark.seal.fill", color: .purple)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Розподіл за FSRS")
                        .font(.headline)

                    let ratings = store.termTracks.values.compactMap { $0.finalRating }
                    let easyCount = ratings.filter { $0 == .easy }.count
                    let goodCount = ratings.filter { $0 == .good }.count
                    let hardCount = ratings.filter { $0 == .hard }.count
                    let againCount = ratings.filter { $0 == .again }.count

                    HStack {
                        ratingBadge("Легко", count: easyCount, color: .green)
                        ratingBadge("Добре", count: goodCount, color: .blue)
                        ratingBadge("Важко", count: hardCount, color: .orange)
                        ratingBadge("Знову", count: againCount, color: .red)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding(.horizontal)

            Button {
                store.send(.restartTapped)
            } label: {
                Text("Розпочати нову сесію")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .cornerRadius(14)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func ratingBadge(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(10)
    }
}

#Preview {
    LearningSummaryView(
        store: Store(
            initialState: LearningSummaryFeature.State(
                completedTermsCount: 5,
                totalExercisesCount: 20,
                termTracks: [:]
            )
        ) {
            LearningSummaryFeature()
        }
    )
}
