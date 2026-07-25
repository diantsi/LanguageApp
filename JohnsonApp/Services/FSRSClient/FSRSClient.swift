//
//  FSRSClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

struct FSRSClient: Sendable {
    var schedule: @Sendable (LearningProgress, Rating, Date) -> LearningProgress
}

extension FSRSClient {
    /// Official FSRS-6 default 21 weights
    nonisolated static let defaultWeights: [Double] = [
        0.212,   // w0: initial stability for Again
        1.2931,  // w1: initial stability for Hard
        2.3065,  // w2: initial stability for Good
        8.2956,  // w3: initial stability for Easy
        6.4133,  // w4: initial difficulty base
        0.8334,  // w5: initial difficulty step
        3.0194,  // w6: difficulty update step
        0.001,   // w7: difficulty mean reversion weight
        1.8722,  // w8: recall stability growth factor base
        0.1666,  // w9: recall stability exponent for S
        0.796,   // w10: recall stability exponent for R
        1.4835,  // w11: forget stability base
        0.0614,  // w12: forget stability exponent for D
        0.2629,  // w13: forget stability exponent for S
        1.6483,  // w14: forget stability exponent for R
        0.6014,  // w15: hard penalty factor for recall stability
        1.8729,  // w16: easy bonus factor for recall stability
        0.5425,  // w17: short term S growth factor
        0.0912,  // w18: short term S grade offset
        0.0658,  // w19: short term S exponent for S
        0.1542   // w20: forgetting curve decay parameter
    ]

    nonisolated static func calculateSchedule(
        progress: LearningProgress,
        rating: Rating,
        reviewDate: Date,
        weights: [Double] = defaultWeights,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> LearningProgress {
        let w = weights.count >= 21 ? weights : defaultWeights

        let newStability: Double
        let newDifficulty: Double
        let newRepetitions: Int
        let newLapses: Int

        let g = Double(rating.rawValue)

        if progress.lastReviewDate == nil {
            switch rating {
            case .again: newStability = w[0]
            case .hard:  newStability = w[1]
            case .good:  newStability = w[2]
            case .easy:  newStability = w[3]
            }

            let d0 = w[4] - exp(w[5] * (g - 1.0)) + 1.0
            newDifficulty = min(max(d0, 1.0), 10.0)

            newRepetitions = 1
            newLapses = (rating == .again) ? 1 : 0
        } else {
            let lastReview = progress.lastReviewDate!
            let elapsedDays = max(0.0, reviewDate.timeIntervalSince(lastReview) / 86400.0)

            let s = max(0.1, progress.stability)
            let d = min(max(progress.difficulty, 1.0), 10.0)

            let deltaD = -w[6] * (g - 3.0)
            let linearDamping = (10.0 - d) / 9.0
            let deltaDamped = deltaD * linearDamping
            let d0Four = min(max(w[4] - exp(w[5] * 3.0) + 1.0, 1.0), 10.0)
            let updatedD = w[7] * d0Four + (1.0 - w[7]) * (d + deltaDamped)
            newDifficulty = min(max(updatedD, 1.0), 10.0)

            if elapsedDays == 0.0 {
                // Short-term S formula: S'(S, G) = S * exp(w17 * (G - 3 + w18) * S^(-w19))
                let w17 = w[17]
                let w18 = w[18]
                let w19 = w[19]

                var sInc = exp(w17 * (g - 3.0 + w18) * pow(s, -w19))
                if g >= 3.0 {
                    sInc = max(1.0, sInc)
                }
                newStability = max(0.1, s * sInc)
                newLapses = (rating == .again) ? progress.lapses + 1 : progress.lapses
            } else {
                // Long-term review formula
                let w20 = w[20]
                let factor = pow(0.9, -1.0 / w20) - 1.0
                let r = pow(1.0 + factor * (elapsedDays / s), -w20)

                if rating == .again {
                    // Forget / Lapse
                    let sf = w[11] * pow(newDifficulty, -w[12]) * (pow(s + 1.0, w[13]) - 1.0) * exp(w[14] * (1.0 - r))
                    newStability = max(0.1, min(s, sf))
                    newLapses = progress.lapses + 1
                } else {
                    // Recall / Success
                    let hardFactor = (rating == .hard) ? w[15] : 1.0
                    let easyFactor = (rating == .easy) ? w[16] : 1.0

                    let growth = exp(w[8]) * (11.0 - newDifficulty) * pow(s, -w[9]) * (exp(w[10] * (1.0 - r)) - 1.0) * hardFactor * easyFactor
                    newStability = max(0.1, s * (1.0 + growth))
                    newLapses = progress.lapses
                }
            }

            newRepetitions = progress.repetitions + 1
        }

        // Calculate dueDate rounded to start of day
        let baseDate = calendar.startOfDay(for: reviewDate)
        let daysInterval = Int(round(newStability))

        let daysToAdd: Int
        if rating == .again {
            daysToAdd = 0
        } else {
            daysToAdd = max(1, daysInterval)
        }

        let dueDate = calendar.date(byAdding: .day, value: daysToAdd, to: baseDate) ?? baseDate

        return LearningProgress(
            stability: newStability,
            difficulty: newDifficulty,
            dueDate: dueDate,
            lastReviewDate: reviewDate,
            repetitions: newRepetitions,
            lapses: newLapses
        )
    }
}

extension FSRSClient: DependencyKey {
    static let liveValue = Self(
        schedule: { progress, rating, reviewDate in
            FSRSClient.calculateSchedule(progress: progress, rating: rating, reviewDate: reviewDate)
        }
    )

    static let testValue = Self(
        schedule: { progress, rating, reviewDate in
            FSRSClient.calculateSchedule(progress: progress, rating: rating, reviewDate: reviewDate)
        }
    )

    static let previewValue = Self(
        schedule: { progress, rating, reviewDate in
            FSRSClient.calculateSchedule(progress: progress, rating: rating, reviewDate: reviewDate)
        }
    )
}

extension DependencyValues {
    var fsrsClient: FSRSClient {
        get { self[FSRSClient.self] }
        set { self[FSRSClient.self] = newValue }
    }
}
