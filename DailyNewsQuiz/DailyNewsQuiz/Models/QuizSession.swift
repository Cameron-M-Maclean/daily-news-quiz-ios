import Combine

class QuizSession: ObservableObject, Hashable {
    static func == (lhs: QuizSession, rhs: QuizSession) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }

    let questions: [Question]

    @Published var currentIndex: Int = 0
    @Published var feedbacks: [AnswerFeedback] = []
    @Published var pendingFeedback: AnswerFeedback? = nil
    @Published var isEvaluating: Bool = false
    @Published var isComplete: Bool = false

    init(questions: [Question]) {
        self.questions = questions
    }

    var currentQuestion: Question {
        questions[currentIndex]
    }

    var score: Double {
        feedbacks.reduce(0) { $0 + $1.result.points }
    }

    // Called when the user submits a text answer.
    // Sends it to Claude for evaluation and stores the feedback.
    func submitAnswer(_ answer: String, quizService: QuizService) async {
        await MainActor.run { isEvaluating = true }

        do {
            let feedback = try await quizService.evaluateAnswer(
                question: currentQuestion,
                userAnswer: answer
            )
            await MainActor.run {
                pendingFeedback = feedback
                isEvaluating = false
            }
        } catch {
            let fallback = AnswerFeedback(
                userAnswer: answer,
                feedbackText: "Could not evaluate your answer. Please check your connection.",
                result: .incorrect
            )
            await MainActor.run {
                pendingFeedback = fallback
                isEvaluating = false
            }
        }
    }

    // Called when the user taps "Next Question" after reading their feedback.
    func advanceToNext() {
        guard let feedback = pendingFeedback else { return }
        feedbacks.append(feedback)
        pendingFeedback = nil

        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }
}
