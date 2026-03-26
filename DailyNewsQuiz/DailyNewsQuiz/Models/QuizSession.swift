import Combine

class QuizSession: ObservableObject, Hashable {
    static func == (lhs: QuizSession, rhs: QuizSession) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    let questions: [Question]

    @Published var currentIndex: Int = 0
    @Published var answers: [Int?]
    @Published var isComplete: Bool = false

    init(questions: [Question]) {
        self.questions = questions
        self.answers = Array(repeating: nil, count: questions.count)
    }

    var currentQuestion: Question {
        questions[currentIndex]
    }

    var score: Int {
        answers.enumerated().filter { index, answer in
            answer == questions[index].correctIndex
        }.count
    }

    func submitAnswer(_ selectedIndex: Int) {
        answers[currentIndex] = selectedIndex

        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }
}
