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
            // Header Progress
            if !store.exercises.isEmpty {
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
                        .tint(.blue)
                }
                .padding(.horizontal)
            }

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

            // Bottom Action Bar
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
                            .background(isSubmitDisabled ? Color.gray : Color.blue)
                            .cornerRadius(14)
                    }
                    .disabled(isSubmitDisabled)
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
                        .background(Color.blue.gradient)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }

    private var isSubmitDisabled: Bool {
        guard let exercise = store.currentExercise else { return true }
        if exercise.type == .multipleChoice {
            return store.selectedOption == nil
        } else {
            return store.userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    @ViewBuilder
    private func exerciseCardView(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exerciseTypeTitle(exercise.type))
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
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
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                backgroundColor = Color.green.opacity(0.15)
                borderColor = Color.green
                textColor = .green
            } else if isSelected && !isTarget {
                backgroundColor = Color.red.opacity(0.15)
                borderColor = Color.red
                textColor = .red
            }
        } else if isSelected {
            backgroundColor = Color.blue.opacity(0.15)
            borderColor = Color.blue
            textColor = .blue
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
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
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
        HStack(spacing: 12) {
            Image(systemName: store.isCurrentAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.isCurrentAnswerCorrect ? "Правильно!" : "Неправильно")
                    .font(.headline)

                if let exercise = store.currentExercise, !store.isCurrentAnswerCorrect {
                    Text("Правильна відповідь: \(exercise.targetAnswer)")
                        .font(.subheadline)
                }
            }
            Spacer()
        }
        .padding()
        .foregroundColor(store.isCurrentAnswerCorrect ? .green : .red)
        .background((store.isCurrentAnswerCorrect ? Color.green : Color.red).opacity(0.12))
        .cornerRadius(14)
    }

    private func exerciseTypeTitle(_ type: ExerciseType) -> String {
        switch type {
        case .multipleChoice: return "Множинний вибір"
        case .writeTerm: return "Написати термін"
        case .writeTranslation: return "Написати переклад"
        case .listening: return "Аудіювання"
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
