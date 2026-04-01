#if DEBUG
import Foundation

/// Subclass of QuizService that skips the API and returns canned feedbacks in order.
/// Only compiled in DEBUG builds.
final class MockQuizService: QuizService {
    private let feedbacks: [AnswerFeedback]
    private var callIndex = 0

    init(feedbacks: [AnswerFeedback]) {
        self.feedbacks = feedbacks
        super.init(apiKey: "mock")
    }

    override func evaluateAnswer(question: Question, userAnswer: String) async throws -> AnswerFeedback {
        let template = feedbacks[callIndex % feedbacks.count]
        callIndex += 1
        // Preserve the canned feedbackText/result but reflect what the user actually typed
        return AnswerFeedback(userAnswer: userAnswer, feedbackText: template.feedbackText, result: template.result)
    }
}
#endif
