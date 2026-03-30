import Foundation

struct Question: Identifiable {
    let id: UUID
    let text: String
    let modelAnswer: String

    init(id: UUID = UUID(), text: String, modelAnswer: String) {
        self.id = id
        self.text = text
        self.modelAnswer = modelAnswer
    }
}
