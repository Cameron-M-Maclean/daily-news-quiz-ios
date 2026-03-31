import SwiftUI

struct QuestionView: View {
    @ObservedObject var session: QuizSession
    let quizService: QuizService
    let onDone: () -> Void

    @State private var answerText: String = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProgressView(value: Double(session.currentIndex), total: Double(session.questions.count))

            Text("Question \(session.currentIndex + 1) of \(session.questions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(session.currentQuestion.text)
                .font(.title3)
                .fontWeight(.semibold)

            if let feedback = session.pendingFeedback {
                // Feedback card shown after evaluation
                FeedbackCard(feedback: feedback)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                Button(session.currentIndex == session.questions.count - 1 ? "See Results" : "Next Question") {
                    answerText = ""
                    session.advanceToNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            } else {
                // Answer input shown before submission
                TextField("Your answer...", text: $answerText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4, reservesSpace: true)
                    .focused($fieldIsFocused)
                    .disabled(session.isEvaluating)

                Button(action: submitAnswer) {
                    if session.isEvaluating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit Answer")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || session.isEvaluating)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Today's Quiz")
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $session.isComplete) {
            ResultsView(session: session, onDone: onDone)
        }
        .animation(.spring(duration: 0.35), value: session.pendingFeedback != nil)
        .onAppear { fieldIsFocused = true }
    }

    private func submitAnswer() {
        let answer = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        fieldIsFocused = false

        Task {
            await session.submitAnswer(answer, quizService: quizService)
        }
    }
}

private struct FeedbackCard: View {
    let feedback: AnswerFeedback

    private var icon: String {
        switch feedback.result {
        case .correct: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .incorrect: return "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch feedback.result {
        case .correct: return .green
        case .partial: return .orange
        case .incorrect: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(feedback.feedbackText)
                    .font(.subheadline)
            }

            Text("Your answer: \(feedback.userAnswer)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let session = QuizSession(questions: sampleQuestions)
    return NavigationStack {
        QuestionView(
            session: session,
            quizService: QuizService(apiKey: "preview"),
            onDone: {}
        )
    }
}
