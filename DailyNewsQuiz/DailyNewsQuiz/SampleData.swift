import Foundation

let sampleQuestions: [Question] = [
    Question(
        text: "Which country hosted the 2024 Summer Olympics?",
        modelAnswer: "France hosted the 2024 Summer Olympics in Paris.",
        articleTitle: "Paris 2024: The Summer Olympics return to France",
        articleURL: "https://www.bbc.co.uk/news/articles/paris-olympics-2024"
    ),
    Question(
        text: "Which company became the first to reach a $3 trillion market valuation?",
        modelAnswer: "Apple became the first company to reach a $3 trillion market cap.",
        articleTitle: "Apple becomes first company worth $3 trillion",
        articleURL: "https://www.theguardian.com/technology/apple-3-trillion"
    ),
    Question(
        text: "What is the name of the AI chatbot launched by OpenAI in November 2022?",
        modelAnswer: "OpenAI launched ChatGPT in November 2022.",
        articleTitle: "OpenAI's ChatGPT is the fastest-growing app in history",
        articleURL: "https://www.npr.org/2023/02/08/chatgpt-openai"
    ),
    Question(
        text: "Which country successfully landed a spacecraft near the Moon's south pole in 2023?",
        modelAnswer: "India's Chandrayaan-3 made a successful soft landing near the lunar south pole in August 2023.",
        articleTitle: "India lands on the Moon's south pole in historic first",
        articleURL: "https://www.bbc.co.uk/news/science-environment-chandrayaan-3"
    ),
    Question(
        text: "Who was named TIME magazine's Person of the Year for 2023?",
        modelAnswer: "Taylor Swift was named TIME's Person of the Year for 2023.",
        articleTitle: "Taylor Swift is TIME's Person of the Year 2023",
        articleURL: "https://time.com/person-of-the-year/2023/taylor-swift"
    ),
]

let sampleFeedbacks: [AnswerFeedback] = [
    AnswerFeedback(userAnswer: "France", feedbackText: "Spot on! The 2024 Olympics were held in Paris — the first time France had hosted since 1968.", result: .correct),
    AnswerFeedback(userAnswer: "Microsoft", feedbackText: "Not quite — it was Apple that first crossed $3 trillion, briefly in January 2022 and more consistently from 2023.", result: .incorrect),
    AnswerFeedback(userAnswer: "ChatGPT", feedbackText: "Exactly right! ChatGPT reached 1 million users in just 5 days — faster than any consumer product before it.", result: .correct),
    AnswerFeedback(userAnswer: "China, I think", feedbackText: "Close — it was actually India's Chandrayaan-3 that landed near the lunar south pole in August 2023, making India the fourth country to land on the Moon.", result: .partial),
    AnswerFeedback(userAnswer: "Taylor Swift", feedbackText: "Correct! TIME recognised her for the extraordinary cultural and economic impact of the Eras Tour.", result: .correct),
]
