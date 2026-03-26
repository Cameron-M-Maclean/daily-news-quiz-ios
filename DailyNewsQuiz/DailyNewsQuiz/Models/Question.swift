import Foundation

struct Question: Identifiable {
    let id: UUID
    let text: String
    let options: [String]
    let correctIndex: Int
    let explanation: String

    init(id: UUID = UUID(), text: String, options: [String], correctIndex: Int, explanation: String) {
        self.id = id
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
    }

    var correctAnswer: String {
        options[correctIndex]
    }
}
