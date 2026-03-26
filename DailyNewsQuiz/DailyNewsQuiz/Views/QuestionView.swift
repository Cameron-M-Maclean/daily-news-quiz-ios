import SwiftUI

struct QuestionView: View {
    @ObservedObject var session: QuizSession

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProgressView(value: Double(session.currentIndex), total: Double(session.questions.count))

            Text("Question \(session.currentIndex + 1) of \(session.questions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(session.currentQuestion.text)
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(session.currentQuestion.options.indices, id: \.self) { index in
                    Button(session.currentQuestion.options[index]) {
                        session.submitAnswer(index)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Today's Quiz")
        .navigationDestination(isPresented: $session.isComplete) {
            ResultsView(session: session)
        }
    }
}

#Preview {
    NavigationStack {
        QuestionView(session: QuizSession(questions: sampleQuestions))
    }
}
