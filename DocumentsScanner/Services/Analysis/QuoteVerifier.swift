import Foundation

struct QuoteVerifier: Sendable {
    /// Below this, the quote is treated as invented and the item is dropped.
    var minimumSimilarity: Double

    init(minimumSimilarity: Double = 0.82) {
        self.minimumSimilarity = minimumSimilarity
    }

    func verified(_ checklist: LeaseChecklist, pages: [RecognizedPage]) -> LeaseChecklist {
        LeaseChecklist(
            parties: verified(checklist.parties, pages: pages),
            money: verified(checklist.money, pages: pages),
            dates: verified(checklist.dates, pages: pages),
            obligations: verified(checklist.obligations, pages: pages),
            questionsBeforeSigning: verified(checklist.questionsBeforeSigning, pages: pages)
        )
    }

    func verified(_ items: [ChecklistItem], pages: [RecognizedPage]) -> [ChecklistItem] {
        items.compactMap { item in
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let quote = item.quote.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, let pageIndex = pageIndex(matching: quote, in: pages, preferred: item.pageIndex) else {
                return nil
            }
            return ChecklistItem(
                id: item.id,
                title: title,
                plainExplanation: item.plainExplanation.trimmingCharacters(in: .whitespacesAndNewlines),
                quote: quote,
                pageIndex: pageIndex,
                severity: item.severity
            )
        }
    }

    private func pageIndex(matching quote: String, in pages: [RecognizedPage], preferred: Int) -> Int? {
        let needle = QuoteText.comparable(quote)
        guard !needle.isEmpty else { return nil }
        let ordered = pages.sorted { left, right in
            let leftFirst = left.index == preferred
            let rightFirst = right.index == preferred
            if leftFirst != rightFirst { return leftFirst }
            return left.index < right.index
        }
        if let exact = ordered.first(where: { QuoteText.comparable($0.text).contains(needle) }) {
            return exact.index
        }
        guard needle.count <= 240 else { return nil }
        var bestPage: Int?
        var bestScore = minimumSimilarity
        for page in ordered {
            let score = bestSimilarity(quote: needle, page: QuoteText.comparable(page.text))
            if score > bestScore || (bestPage == nil && score >= bestScore) {
                bestScore = score
                bestPage = page.index
            }
        }
        return bestPage
    }

    private func bestSimilarity(quote: String, page: String) -> Double {
        if quote.isEmpty || page.isEmpty { return 0 }
        if quote.count >= page.count {
            return similarity(quote, page)
        }
        let quoteChars = Array(quote)
        let pageChars = Array(page)
        let width = quoteChars.count
        let step = max(1, width / 8)
        var best = 0.0
        var offset = 0
        while offset + width <= pageChars.count {
            let window = Array(pageChars[offset..<(offset + width)])
            best = max(best, similarity(quoteChars, window))
            if best >= 0.98 { return best }
            offset += step
        }
        let tail = pageChars.count - width
        if tail > 0, tail % step != 0 {
            best = max(best, similarity(quoteChars, Array(pageChars[tail...])))
        }
        return best
    }

    private func similarity(_ left: String, _ right: String) -> Double {
        similarity(Array(left), Array(right))
    }

    private func similarity(_ left: [Character], _ right: [Character]) -> Double {
        let longest = max(left.count, right.count)
        guard longest > 0 else { return 1 }
        return 1 - (Double(levenshtein(left, right)) / Double(longest))
    }

    private func levenshtein(_ left: [Character], _ right: [Character]) -> Int {
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }
        var previous = Array(0...right.count)
        var current = Array(repeating: 0, count: right.count + 1)
        for leftIndex in 1...left.count {
            current[0] = leftIndex
            for rightIndex in 1...right.count {
                let cost = left[leftIndex - 1] == right[rightIndex - 1] ? 0 : 1
                current[rightIndex] = min(
                    current[rightIndex - 1] + 1,
                    previous[rightIndex] + 1,
                    previous[rightIndex - 1] + cost
                )
            }
            swap(&previous, &current)
        }
        return previous[right.count]
    }
}
