import SwiftUI

struct ResultsView: View {
    @ObservedObject var session: QuizSession
    @EnvironmentObject var statsManager: StatsManager
    let onDone: () -> Void

    @State private var statChanges: StatChanges? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: scoreIcon)
                .font(.system(size: 64))
                .foregroundStyle(scoreColor)

            Text(scoreHeading)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(scoreText) out of \(session.questions.count)")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let changes = statChanges {
                StatChangesRow(changes: changes)
                    .transition(.opacity)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(session.questions.indices, id: \.self) { index in
                        QuestionSummaryRow(
                            question: session.questions[index],
                            feedback: session.feedbacks[index],
                            number: index + 1
                        )
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
        .task {
            guard statChanges == nil else { return }
            let changes = statsManager.recordCompletion(
                correct: session.score,
                total: session.questions.count
            )

            withAnimation(.easeIn(duration: 0.4)) {
                statChanges = changes
            }
        }
    }

    // Shows "4" or "4.5" — avoids displaying unnecessary decimal for whole numbers
    private var scoreText: String {
        session.score == Double(Int(session.score))
            ? "\(Int(session.score))"
            : String(format: "%.1f", session.score)
    }

    private var maxScore: Double { Double(session.questions.count) }

    private var scoreIcon: String {
        if session.score == maxScore { return "star.fill" }
        if session.score >= maxScore / 2 { return "hand.thumbsup.fill" }
        return "arrow.counterclockwise"
    }

    private var scoreColor: Color {
        if session.score == maxScore { return .yellow }
        if session.score >= maxScore / 2 { return .green }
        return .secondary
    }

    private var scoreHeading: String {
        if session.score == maxScore { return "Perfect score!" }
        if session.score >= maxScore / 2 { return "Well done!" }
        return "Keep it up!"
    }
}

private struct StatChangesRow: View {
    let changes: StatChanges

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(changes.streakAfter) \(changes.streakAfter == 1 ? "day" : "days")")
                        .font(.headline)
                    if changes.streakAfter != changes.streakBefore {
                        Text("(+\(changes.streakAfter - changes.streakBefore))")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Answered Correctly")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(changes.percentageAfter))%")
                        .font(.headline)
                    if let before = changes.percentageBefore {
                        let delta = Int(changes.percentageAfter) - Int(before)
                        if delta != 0 {
                            Text(delta > 0 ? "(+\(delta)%)" : "(\(delta)%)")
                                .font(.caption)
                                .foregroundStyle(delta > 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuestionSummaryRow: View {
    let question: Question
    let feedback: AnswerFeedback
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: feedback.result == .correct ? "checkmark.circle.fill" : feedback.result == .partial ? "circle.lefthalf.filled" : "xmark.circle.fill")
                    .foregroundStyle(feedback.result == .correct ? .green : feedback.result == .partial ? .orange : .red)
                Text("Q\(number): \(question.text)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Your answer: \(feedback.userAnswer)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(feedback.feedbackText)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let session = QuizSession(questions: sampleQuestions)
    for feedback in sampleFeedbacks {
        session.feedbacks.append(feedback)
    }
    return NavigationStack {
        ResultsView(session: session, onDone: {})
            .environmentObject(StatsManager())
    }
}
