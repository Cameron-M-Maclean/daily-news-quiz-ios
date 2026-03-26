import SwiftUI

struct HomeView: View {
    @State private var session: QuizSession? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("Daily News Quiz")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("5 questions from today's headlines")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Start Quiz") {
                    session = QuizSession(questions: sampleQuestions)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationDestination(item: $session) { session in
                QuestionView(session: session)
            }
        }
    }
}

#Preview {
    HomeView()
}
