import Foundation

enum AnswerResult: String {
    case correct
    case partial
    case incorrect

    // Points awarded: full, half, none
    var points: Double {
        switch self {
        case .correct: return 1.0
        case .partial: return 0.5
        case .incorrect: return 0.0
        }
    }
}

struct AnswerFeedback {
    let userAnswer: String
    let feedbackText: String
    let result: AnswerResult
}
