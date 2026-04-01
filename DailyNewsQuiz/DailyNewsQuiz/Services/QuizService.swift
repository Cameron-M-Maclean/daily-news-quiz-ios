import Foundation

class QuizService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private enum Model {
        static let generation = "claude-sonnet-4-6"  // quality needed for question writing
        static let evaluation = "claude-haiku-4-5-20251001"  // simple classification task, cheapest
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Question Generation

    func generateQuestions(from articles: [Article]) async throws -> [Question] {
        // Headlines with URLs — summaries skipped to save tokens; URL included so Claude can associate questions with sources
        let headlines = articles.map { "- [\($0.source)] \($0.title) (url: \($0.url))" }.joined(separator: "\n")

        let system = """
        You generate questions for a daily news quiz aimed at informed, curious non-experts.

        Golden rule: never embed the answer in the question.
        Bad: "Iran cut oil supplies, pushing prices up — why did Australia introduce free transport?"
        Good: "Two Australian states announced free public transport this week — why do you think they made that decision?"

        Vary question types across the 5 questions:
        1. Factual recall ("Who/what/where did X?") — 1-2 of these
        2. Causal reasoning ("Why do you think X happened?")
        3. Critical thinking ("What are the broader implications of X?")
        4. Perspective-taking ("Why might X be doing this, from their point of view?")
        5. Pattern recognition ("What does this remind you of?")

        Keep each question to 2-3 sentences. Cover varied topics. Do not use emoji.
        Respond ONLY with valid JSON — no markdown, no explanation.
        Format: [{"question": "...", "modelAnswer": "...", "articleTitle": "...", "articleURL": "..."}]
        """

        let user = "Headlines:\n\(headlines)"

        let responseText = try await callClaude(system: system, user: user, model: Model.generation, maxTokens: 1024)
        return try parseQuestions(from: responseText)
    }

    // MARK: - Answer Evaluation

    func evaluateAnswer(question: Question, userAnswer: String) async throws -> AnswerFeedback {
        let system = """
        You evaluate quiz answers. Be warm and conversational — like a knowledgeable friend, not an examiner.

        Classify as "correct" (got the key point), "partial" (something right but missing an element), or "incorrect" (missed the mark or said they don't know).

        - correct: Confirm clearly, add 1 sentence of interesting context
        - partial: Acknowledge what they got right, fill in the gap without condescension
        - incorrect: Briefly explain what happened, frame it as worth knowing. If "I don't know", explain it as a short story

        2-3 sentences max. No emoji.
        Respond ONLY with valid JSON: {"result": "correct"|"partial"|"incorrect", "feedbackText": "..."}
        """

        let user = """
        Question: \(question.text)
        Model answer: \(question.modelAnswer)
        User's answer: \(userAnswer)
        """

        let responseText = try await callClaude(system: system, user: user, model: Model.evaluation, maxTokens: 256)
        return try parseFeedback(from: responseText, userAnswer: userAnswer)
    }

    // MARK: - Claude API

    private func callClaude(system: String, user: String, model: String, maxTokens: Int) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": user]
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

        if let usage = json["usage"] as? [String: Any],
           let inputTokens = usage["input_tokens"] as? Int,
           let outputTokens = usage["output_tokens"] as? Int {
            print("[API] \(model) — in: \(inputTokens) / out: \(outputTokens)")
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
            return Question(
                text: q,
                modelAnswer: a,
                articleTitle: item["articleTitle"] as? String,
                articleURL: item["articleURL"] as? String
            )
        }
    }

    private func parseFeedback(from text: String, userAnswer: String) throws -> AnswerFeedback {
        guard let data = extractJSON(from: text).data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultString = json["result"] as? String,
              let feedbackText = json["feedbackText"] as? String
        else { throw QuizError.parseError }

        let result = AnswerResult(rawValue: resultString) ?? .incorrect
        return AnswerFeedback(userAnswer: userAnswer, feedbackText: feedbackText, result: result)
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
