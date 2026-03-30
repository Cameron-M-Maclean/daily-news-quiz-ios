import Foundation

let sampleQuestions: [Question] = [
    Question(
        text: "Which country hosted the 2024 Summer Olympics?",
        modelAnswer: "France hosted the 2024 Summer Olympics in Paris."
    ),
    Question(
        text: "Which company became the first to reach a $3 trillion market valuation?",
        modelAnswer: "Apple became the first company to reach a $3 trillion market cap."
    ),
    Question(
        text: "What is the name of the AI chatbot launched by OpenAI in November 2022?",
        modelAnswer: "OpenAI launched ChatGPT in November 2022."
    ),
    Question(
        text: "Which country successfully landed a spacecraft near the Moon's south pole in 2023?",
        modelAnswer: "India's Chandrayaan-3 made a successful soft landing near the lunar south pole in August 2023."
    ),
    Question(
        text: "Who was named TIME magazine's Person of the Year for 2023?",
        modelAnswer: "Taylor Swift was named TIME's Person of the Year for 2023."
    ),
]

let sampleFeedbacks: [AnswerFeedback] = [
    AnswerFeedback(userAnswer: "France", feedbackText: "Correct! The 2024 Olympics were held in Paris, France.", isCorrect: true),
    AnswerFeedback(userAnswer: "Microsoft", feedbackText: "Not quite — it was Apple, not Microsoft, that first hit $3 trillion.", isCorrect: false),
]
