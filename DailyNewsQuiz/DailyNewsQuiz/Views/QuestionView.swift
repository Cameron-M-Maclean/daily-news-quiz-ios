import SwiftUI

struct QuestionView: View {
    @ObservedObject var session: QuizSession
    let quizService: QuizService
    let onDone: () -> Void
    var testAnswers: [String]? = nil

    @State private var answerText: String = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Progress
            ProgressView(value: Double(session.currentIndex), total: Double(session.questions.count))
                .padding(.horizontal, 28)
                .padding(.top, 8)

            Text("Question \(session.currentIndex + 1) of \(session.questions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 12)

            Spacer()

            // Question text — hero element
            Text(session.currentQuestion.text)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

            Spacer()

            // Input / feedback section
            VStack(spacing: 16) {
                if let feedback = session.pendingFeedback {
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
                    TextField("Your answer...", text: $answerText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(6, reservesSpace: true)
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
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .navigationTitle("Today's Quiz")
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $session.isComplete) {
            ResultsView(session: session, onDone: onDone)
        }
        .animation(.spring(duration: 0.35), value: session.pendingFeedback != nil)
        .onAppear { prefillIfNeeded(); fieldIsFocused = true }
        .onChange(of: session.currentIndex) { prefillIfNeeded() }
    }

    private func prefillIfNeeded() {
        guard let answers = testAnswers, session.currentIndex < answers.count else { return }
        answerText = answers[session.currentIndex]
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
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
                Text(feedback.feedbackText)
                    .font(.subheadline)
            }

            Text("Your answer: \(feedback.userAnswer)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
