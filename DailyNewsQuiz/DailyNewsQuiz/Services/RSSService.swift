import Foundation

struct Article {
    let title: String
    let summary: String
    let source: String
}

class RSSService: NSObject, XMLParserDelegate {
    private let feeds: [(url: String, source: String)] = [
        ("https://feeds.bbci.co.uk/news/world/rss.xml", "BBC News"),
        ("https://feeds.npr.org/1001/rss.xml", "NPR News"),
        ("https://www.theguardian.com/world/rss", "The Guardian"),
    ]

    // Fetches all three feeds concurrently and returns up to 15 articles total.
    // If an individual feed fails, it is skipped rather than failing the whole fetch.
    func fetchArticles() async throws -> [Article] {
        let all: [Article] = await withTaskGroup(of: [Article].self) { group in
            for feed in feeds {
                group.addTask {
                    (try? await self.fetchFeed(url: feed.url, source: feed.source)) ?? []
                }
            }

            var results: [Article] = []
            for await articles in group {
                results.append(contentsOf: articles)
            }
            return results
        }

        guard !all.isEmpty else {
            throw RSSError.noArticlesFetched
        }
        return all
    }

    // Fetches and parses a single RSS feed.
    private func fetchFeed(url: String, source: String) async throws -> [Article] {
        guard let feedURL = URL(string: url) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: feedURL)

        let parser = RSSParser(source: source)
        return parser.parse(data: data)
    }
}

enum RSSError: LocalizedError {
    case noArticlesFetched
    var errorDescription: String? { "Could not fetch any news articles. Check your connection." }
}

// A simple SAX-style XML parser for RSS <item> elements.
// SAX means it reads the XML top-to-bottom rather than loading the whole tree into memory.
private class RSSParser: NSObject, XMLParserDelegate {
    private let source: String
    private var articles: [Article] = []

    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var insideItem = false

    init(source: String) {
        self.source = source
    }

    func parse(data: Data) -> [Article] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return Array(articles.prefix(3))
    }

    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = element
        if element == "item" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description": currentDescription += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
        if element == "item" {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let summary = currentDescription
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            if !title.isEmpty {
                articles.append(Article(title: title, summary: summary, source: source))
            }
            insideItem = false
        }
    }
}
