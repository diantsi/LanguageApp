//
//  LearningSetupView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct LearningSetupView: View {
    @Bindable var store: StoreOf<LearningSetupFeature>

    init(store: StoreOf<LearningSetupFeature>) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                if let sessionStore = store.scope(state: \.session, action: \.session) {
                    LearningSessionView(store: sessionStore)
                } else if let summaryStore = store.scope(state: \.summary, action: \.summary) {
                    LearningSummaryView(store: summaryStore)
                } else {
                    setupView
                }
            }
            .navigationTitle("Навчання")
            .onAppear {
                store.send(.onAppear)
            }
        }
    }


    private var setupView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)
                    .padding(.bottom, 8)

                Text("Інтервальне повторення")
                    .font(.title2.bold())

                Text("Повторення карток, запланованих на сьогодні за алгоритмом FSRS.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            if store.isLoading {
                ProgressView("Завантаження карток...")
                    .padding(.top, 40)
            } else if store.termsToLearn.isEmpty {
                noTermsToLearnView
            } else {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Доступно карток на сьогодні")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("\(store.termsLimit)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Розмір сесії")
                            .font(.headline)

                        HStack {
                            Text("Кількість карток для повторення:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(store.userLimit)")
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        }

                        Stepper(
                            value: $store.userLimit.sending(\.limitChanged),
                            in: 1...store.termsLimit
                        ) {
                            Text("Змінити ліміт (1 - \(store.termsLimit))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    Button {
                        store.send(.startLearningTapped)
                    } label: {
                        HStack {
                            Text("Розпочати сесію")
                                .font(.headline)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.gradient)
                        .cornerRadius(14)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }
    
    
    private var noTermsToLearnView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            Text("Все повторено!")
                .font(.headline)

            Text("Наразі немає карток для повторення. Додайте нові терміни у Словнику або поверніться пізніше!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    LearningSetupView(
        store: Store(
            initialState: LearningSetupFeature.State()
        ) {
            LearningSetupFeature()
        } withDependencies: {
            $0.persistenceClient = .previewValue
            $0.fsrsClient = .previewValue
            $0.speechClient = .previewValue
        }
    )
}
