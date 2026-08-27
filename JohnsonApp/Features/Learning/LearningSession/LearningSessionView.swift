//
//  LearningSessionView.swift
//  JohnsonApp
//

import ComposableArchitecture
import SwiftUI

struct LearningSessionView: View {
    @Bindable var store: StoreOf<LearningSessionFeature>

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                HStack {
                    Text("Вправа \(store.currentIndex + 1) з \(store.exercises.count)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Пройдено карток: \(store.completedTermsCount) / \(store.totalTermsInSession)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(store.currentIndex + 1), total: Double(store.exercises.count))
                    .tint(AppTheme.sageGreen)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 20) {
                    if let exercise = store.currentExercise {
                        exerciseCardView(exercise)
                    }

                    if store.isAnswerSubmitted {
                        resultFeedbackBanner
                    }
                }
                .padding(.horizontal)
            }

            VStack {
                if !store.isAnswerSubmitted {
                    Button {
                        store.send(.submitAnswer)
                    } label: {
                        Text("Перевірити")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(store.isSubmitDisabled ? Color.gray.opacity(0.4) : AppTheme.accentBlue)
                            .cornerRadius(14)
                    }
                    .disabled(store.isSubmitDisabled)
                } else {
                    Button {
                        store.send(.nextExercise)
                    } label: {
                        HStack {
                            Text(store.currentIndex + 1 == store.exercises.count ? "Завершити сесію" : "Наступна вправа")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentBlue)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(AppTheme.backgroundColor)
    }

    @ViewBuilder
    private func exerciseCardView(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exercise.type.title)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentBlue.opacity(0.12))
                    .foregroundColor(AppTheme.accentBlue)
                    .clipShape(Capsule())

                Spacer()
            }

            switch exercise.type {
            case .multipleChoice:
                Text("Оберіть правильний термін для:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(exercise.prompt)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                if let options = exercise.options {
                    VStack(spacing: 10) {
                        ForEach(options, id: \.self) { option in
                            optionButton(option, targetAnswer: exercise.targetAnswer)
                        }
                    }
                    .padding(.top, 8)
                }

            case .writeTerm:
                Text("Напишіть термін для:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(exercise.prompt)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                TextField("Введіть термін...", text: $store.userAnswer.sending(\.setUserAnswer))
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(store.isAnswerSubmitted)

            case .writeTranslation:
                Text("Напишіть переклад для:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(exercise.prompt)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                TextField("Введіть переклад...", text: $store.userAnswer.sending(\.setUserAnswer))
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(store.isAnswerSubmitted)

            case .listening:
                Text("Послухайте та напишіть слово:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    store.send(.playListeningAudio)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title)
                        Text("Озвучити")
                            .font(.headline)
                    }
                    .foregroundColor(AppTheme.accentBlue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accentBlue.opacity(0.1))
                    .cornerRadius(12)
                }

                TextField("Введіть почуте слово...", text: $store.userAnswer.sending(\.setUserAnswer))
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(store.isAnswerSubmitted)
            }
        }
        .padding(16)
        .appCardStyle(cornerRadius: 16, borderColor: AppTheme.sageGreen.opacity(0.3), borderWidth: 1.5)
    }

    private func optionButton(_ option: String, targetAnswer: String) -> some View {
        let isSelected = store.selectedOption == option
        let isSubmitted = store.isAnswerSubmitted
        let isTarget = AnswerValidator.normalize(option) == AnswerValidator.normalize(targetAnswer)

        var backgroundColor: Color = Color(uiColor: .tertiarySystemGroupedBackground)
        var borderColor: Color = Color.clear
        var textColor: Color = .primary

        if isSubmitted {
            if isTarget {
                backgroundColor = AppTheme.sageGreen.opacity(0.15)
                borderColor = AppTheme.sageGreen
                textColor = AppTheme.sageGreen
            } else if isSelected && !isTarget {
                backgroundColor = Color.red.opacity(0.15)
                borderColor = Color.red
                textColor = .red
            }
        } else if isSelected {
            backgroundColor = AppTheme.accentBlue.opacity(0.15)
            borderColor = AppTheme.accentBlue
            textColor = AppTheme.accentBlue
        }

        return Button {
            store.send(.selectOption(option))
        } label: {
            HStack {
                Text(option)
                    .font(.body.weight(.medium))
                    .foregroundColor(textColor)
                Spacer()
                if isSubmitted {
                    if isTarget {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.sageGreen)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.accentBlue)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 2))
            .cornerRadius(12)
        }
        .disabled(isSubmitted)
    }

    private var resultFeedbackBanner: some View {
        VStack(spacing: 12) {
            if store.isCurrentAnswerCorrect {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.isOverridden ? "Зараховано як правильно!" : "Правильно!")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .foregroundColor(.green)
                .background(Color.green.opacity(0.12))
                .cornerRadius(14)
            } else if case .typo = store.validationResult, !store.isOverridden {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Майже правильно! (Описка в 1 букву)")
                                .font(.headline)
                                .foregroundColor(.orange)

                            if let exercise = store.currentExercise {
                                Text("Правильна відповідь: \(exercise.targetAnswer)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button {
                            store.send(.markAsCorrect)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Зарахувати відповідь")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.green)
                            .cornerRadius(10)
                        }

                        Button {
                            store.send(.markAsIncorrect)
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Вважати помилкою")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.12))
                .cornerRadius(14)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Неправильно")
                                .font(.headline)
                                .foregroundColor(.red)

                            if let exercise = store.currentExercise {
                                Text("Правильна відповідь: \(exercise.targetAnswer)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }

                    Button {
                        store.send(.markAsCorrect)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Зарахувати як правильно")
                        }
                        .font(.footnote.bold())
                        .foregroundColor(.green)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.12))
                .cornerRadius(14)
            }
        }
    }
}

#Preview {
    let mockTerm = Term.mockList.first ?? Term(termText: "apple", translation: "яблуко")
    let mockExercise = Exercise(
        term: mockTerm,
        type: .multipleChoice,
        prompt: "яблуко",
        targetAnswer: "apple",
        options: ["apple", "banana", "cherry", "date"]
    )
    return LearningSessionView(
        store: Store(
            initialState: LearningSessionFeature.State(
                exercises: [mockExercise]
            )
        ) {
            LearningSessionFeature()
        }
    )
}
