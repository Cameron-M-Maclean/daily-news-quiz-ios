import Foundation

struct Question: Identifiable {
    let id: UUID
    let text: String
    let modelAnswer: String
    let articleTitle: String?
    let articleURL: String?

    init(id: UUID = UUID(), text: String, modelAnswer: String, articleTitle: String? = nil, articleURL: String? = nil) {
        self.id = id
        self.text = text
        self.modelAnswer = modelAnswer
        self.articleTitle = articleTitle
        self.articleURL = articleURL
    }
}
