import SwiftUI

struct HomeView: View {
    @EnvironmentObject var statsManager: StatsManager
    @State private var session: QuizSession? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let rssService = RSSService()
    private let quizService = QuizService(apiKey: Config.anthropicAPIKey)

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

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Fetching today's news...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Start Quiz") {
                        startQuiz()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if statsManager.hasStats {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(statsManager.currentStreak) \(statsManager.currentStreak == 1 ? "day" : "days")")
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Answered Correctly")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(statsManager.answeredCorrectlyPercentage))%")
                                .font(.headline)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .navigationDestination(item: $session) { session in
                QuestionView(session: session, quizService: quizService, onDone: { self.session = nil })
            }
        }
    }

    private func startQuiz() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let articles = try await rssService.fetchArticles()
                let questions = try await quizService.generateQuestions(from: articles)
                await MainActor.run {
                    session = QuizSession(questions: questions)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(StatsManager())
}
