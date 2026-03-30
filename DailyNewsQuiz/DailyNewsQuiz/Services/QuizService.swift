import Foundation

class QuizService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-opus-4-6"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Question Generation

    // Takes a list of news articles and asks Claude to generate 5 open-ended quiz questions.
    func generateQuestions(from articles: [Article]) async throws -> [Question] {
        let articleText = articles.map { "- [\($0.source)] \($0.title): \($0.summary)" }.joined(separator: "\n")

        let prompt = """
        You are a news quiz generator. Based on the following news headlines and summaries, generate exactly 5 open-ended quiz questions.

        Articles:
        \(articleText)

        Rules:
        - Questions should be accessible to a general audience — no specialist knowledge required
        - Focus on the main facts: who, what, where, why
        - A correct answer only needs to capture the key point, not every detail
        - Each question should be answerable in 1-2 sentences
        - Cover a variety of topics from the articles
        - Respond ONLY with valid JSON — no explanation, no markdown

        Format:
        [
          {
            "question": "...",
            "modelAnswer": "..."
          }
        ]
        """

        let responseText = try await callClaude(prompt: prompt)
        return try parseQuestions(from: responseText)
    }

    // MARK: - Answer Evaluation

    // Sends the user's answer to Claude alongside the question and model answer for evaluation.
    func evaluateAnswer(question: Question, userAnswer: String) async throws -> AnswerFeedback {
        let prompt = """
        You are evaluating a quiz answer. Be encouraging but honest.

        Question: \(question.text)
        Model answer: \(question.modelAnswer)
        User's answer: \(userAnswer)

        Assess whether the user's answer is essentially correct (they understood the key point), partially correct, or incorrect.
        Give 2-3 sentences of friendly feedback explaining what they got right or wrong.

        Respond ONLY with valid JSON — no explanation, no markdown:
        {
          "isCorrect": true or false,
          "feedbackText": "..."
        }
        """

        let responseText = try await callClaude(prompt: prompt)
        return try parseFeedback(from: responseText, userAnswer: userAnswer)
    }

    // MARK: - Claude API

    private func callClaude(prompt: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw QuizError.apiError
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            throw QuizError.unexpectedResponse
        }

        return text
    }

    // MARK: - Parsing

    private func parseQuestions(from text: String) throws -> [Question] {
        guard let data = extractJSON(from: text).data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { throw QuizError.parseError }

        return array.compactMap { item in
            guard let q = item["question"] as? String,
                  let a = item["modelAnswer"] as? String
            else { return nil }
            return Question(text: q, modelAnswer: a)
        }
    }

    private func parseFeedback(from text: String, userAnswer: String) throws -> AnswerFeedback {
        guard let data = extractJSON(from: text).data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isCorrect = json["isCorrect"] as? Bool,
              let feedbackText = json["feedbackText"] as? String
        else { throw QuizError.parseError }

        return AnswerFeedback(userAnswer: userAnswer, feedbackText: feedbackText, isCorrect: isCorrect)
    }

    // Strips markdown code fences if Claude wraps the JSON in ```json ... ```
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            let lines = trimmed.components(separatedBy: "\n")
            let stripped = lines.dropFirst().dropLast()
            return stripped.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}

enum QuizError: LocalizedError {
    case apiError
    case unexpectedResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .apiError: return "The API returned an error. Check your API key."
        case .unexpectedResponse: return "Received an unexpected response from the API."
        case .parseError: return "Could not read the response from Claude."
        }
    }
}
