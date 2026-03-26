import SwiftUI

struct ResultsView: View {
    @ObservedObject var session: QuizSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: scoreIcon)
                .font(.system(size: 64))
                .foregroundStyle(scoreColor)

            Text(scoreHeading)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(session.score) out of \(session.questions.count) correct")
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(session.questions) { question in
                        QuestionSummaryRow(question: question, session: session)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            Button("Done") {
                dismiss()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
    }

    private var scoreIcon: String {
        switch session.score {
        case session.questions.count: return "star.fill"
        case (session.questions.count / 2)...: return "hand.thumbsup.fill"
        default: return "arrow.counterclockwise"
        }
    }

    private var scoreColor: Color {
        switch session.score {
        case session.questions.count: return .yellow
        case (session.questions.count / 2)...: return .green
        default: return .secondary
        }
    }

    private var scoreHeading: String {
        switch session.score {
        case session.questions.count: return "Perfect score!"
        case (session.questions.count / 2)...: return "Well done!"
        default: return "Keep it up!"
        }
    }
}

private struct QuestionSummaryRow: View {
    let question: Question
    let session: QuizSession

    private var questionIndex: Int? {
        session.questions.firstIndex(where: { $0.id == question.id })
    }

    private var selectedAnswer: Int? {
        guard let index = questionIndex else { return nil }
        return session.answers[index]
    }

    private var isCorrect: Bool {
        selectedAnswer == question.correctIndex
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
                Text(question.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if let selected = selectedAnswer, !isCorrect {
                Text("Your answer: \(question.options[selected])")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("Correct: \(question.correctAnswer)")
                .font(.caption)
                .foregroundStyle(.green)

            Text(question.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let session = QuizSession(questions: sampleQuestions)
    session.submitAnswer(1)
    session.submitAnswer(2)
    session.submitAnswer(3)
    session.submitAnswer(3)
    session.submitAnswer(1)
    return NavigationStack {
        ResultsView(session: session)
    }
}
