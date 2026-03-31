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
        You are generating questions for a daily news quiz aimed at informed, curious non-experts.

        Articles:
        \(articleText)

        Rules:
        - Golden rule: never embed the answer in the question. Bad: "Iran cut oil supplies, pushing prices up — why did Australia introduce free transport?" Good: "Two Australian states announced free public transport this week — why do you think they made that decision?"
        - Vary the question types across the 5 questions — use a mix of:
          1. Factual recall ("Who/what/where did X?") — 1-2 of these, easier, good for warming up
          2. Causal reasoning ("Why do you think X happened?")
          3. Critical thinking ("What are the broader implications of X?")
          4. Perspective-taking ("Why might X be doing this, from their point of view?")
          5. Pattern recognition ("This follows a familiar pattern — what does it remind you of?")
        - Aim for questions where an informed non-expert can make a reasonable educated guess
        - If the topic is niche, include enough context in the question that lateral thinking can get close
        - Keep each question to 2-3 sentences with a single clear prompt at the end
        - Cover a variety of topics — avoid 5 geopolitical questions in a row
        - Do not use emoji
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
        You are evaluating a quiz answer. Your tone should be warm and conversational — like a knowledgeable friend, not an examiner.

        Question: \(question.text)
        Model answer: \(question.modelAnswer)
        User's answer: \(userAnswer)

        Classify the answer as one of:
        - "correct": they got the key point, even if not word-for-word
        - "partial": they got something right but missed an important element
        - "incorrect": they missed the mark, or said they don't know

        Response guidelines:
        - correct: Confirm clearly (e.g. "Spot on!" or "Exactly right!"), then add 1-2 sentences of interesting context they didn't mention
        - partial: Acknowledge what they got right first, then fill in what was missing without being condescending
        - incorrect: Don't dwell — briefly explain what happened and frame it as something worth knowing. If they said "I don't know", deliver a concise engaging explanation as if telling a story

        Keep the response to 2-4 sentences. Do not use emoji.
        Respond ONLY with valid JSON — no explanation, no markdown:
        {
          "result": "correct" or "partial" or "incorrect",
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
