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
                AppTheme.backgroundColor
                    .ignoresSafeArea()

                if let sessionStore = store.scope(state: \.session, action: \.session) {
                    LearningSessionView(store: sessionStore)
                } else if let summaryStore = store.scope(state: \.summary, action: \.summary) {
                    LearningSummaryView(store: summaryStore)
                } else {
                    ScrollView {
                        setupView
                    }
                    .safeAreaInset(edge: .top) {
                        HeaderBannerView(title: "пора вчитись", imageName: "studycat")
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }


    private var setupView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.accentBlue)
                    .padding(.bottom, 4)

                Text("Інтервальне повторення")
                    .font(.title2.bold())

                Text("Повторення карток, запланованих на сьогодні за алгоритмом FSRS.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 16)

            if store.isLoading {
                ProgressView("Завантаження карток...")
                    .tint(AppTheme.sageGreen)
                    .padding(.top, 40)
            } else if store.termsToLearn.isEmpty {
                noTermsToLearnView
            } else {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Доступно карток на сьогодні")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("\(store.termsLimit)")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.sageGreen)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .appCardStyle(cornerRadius: 16, borderColor: AppTheme.sageGreen.opacity(0.3), borderWidth: 1)

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
                                .foregroundColor(AppTheme.accentBlue)
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
                    .padding(16)
                    .appCardStyle(cornerRadius: 16, borderColor: AppTheme.sageGreen.opacity(0.3), borderWidth: 1)

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
                        .background(AppTheme.accentBlue)
                        .cornerRadius(14)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
    
    
    private var noTermsToLearnView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.sageGreen)

            Text("Все повторено!")
                .font(.headline)

            Text("Наразі немає карток для повторення. Додайте нові терміни у Словнику або поверніться пізніше!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(20)
        .appCardStyle(cornerRadius: 16, borderColor: AppTheme.sageGreen.opacity(0.3), borderWidth: 1)
        .padding(.horizontal, 20)
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
