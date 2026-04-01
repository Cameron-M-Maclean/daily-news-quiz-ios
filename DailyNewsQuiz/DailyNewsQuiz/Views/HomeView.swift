import SwiftUI

struct HomeView: View {
    @EnvironmentObject var statsManager: StatsManager
    @State private var session: QuizSession? = nil
    @State private var testSession: QuizSession? = nil
    @State private var testQuizSession: QuizSession? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let rssService = RSSService()
    private let quizService = QuizService(apiKey: Config.anthropicAPIKey)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Spacer()

                // Hero
                VStack(spacing: 20) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("Daily News Quiz")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("5 questions from today's headlines")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }

                // Primary action
                VStack(spacing: 14) {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Fetching today's news...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
                        Button("Start Quiz") {
                            startQuiz()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }

                    #if DEBUG
                    Button("Test Questions") {
                        testQuizSession = QuizSession(questions: sampleQuestions)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button("Test Results") {
                        let s = QuizSession(questions: sampleQuestions)
                        s.feedbacks = sampleFeedbacks
                        s.isComplete = true
                        testSession = s
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    #endif
                }

                // Stats bar
                if statsManager.hasStats {
                    Divider()
                        .padding(.top, 28)

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
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
            .padding(.top, 16)
            .navigationDestination(item: $session) { session in
                QuestionView(session: session, quizService: quizService, onDone: { self.session = nil })
            }
            .navigationDestination(item: $testSession) { session in
                ResultsView(session: session, onDone: { self.testSession = nil })
            }
            #if DEBUG
            .navigationDestination(item: $testQuizSession) { session in
                QuestionView(
                    session: session,
                    quizService: MockQuizService(feedbacks: sampleFeedbacks),
                    onDone: { self.testQuizSession = nil },
                    testAnswers: sampleFeedbacks.map(\.userAnswer)
                )
            }
            #endif
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
