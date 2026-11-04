import Foundation

/// Finds a checklist quote inside a page, and the words worth searching for.
enum QuoteSpan {
    struct Parts: Equatable, Sendable {
        let before: String
        let match: String
        let after: String
    }

    static func parts(of quote: String, in page: String) -> Parts? {
        guard let range = range(of: quote, in: page), !range.isEmpty else { return nil }
        return Parts(
            before: String(page[..<range.lowerBound]),
            match: String(page[range]),
            after: String(page[range.upperBound...])
        )
    }

    /// Search words. A thousands group such as "1,500" or "1.500" counts as one word, "1500".
    static func terms(in text: String) -> [String] {
        tokens(in: text).compactMap { token in
            let term = term(from: token.comparable)
            guard term.contains(where: { $0.isLetter || $0.isNumber }) else { return nil }
            return term
        }
    }

    static func range(of quote: String, in page: String) -> Range<String.Index>? {
        let trimmed = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !page.isEmpty else { return nil }
        if let exact = page.range(of: trimmed) {
            return exact
        }
        if let folded = page.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) {
            return folded
        }
        return alignedRange(quote: trimmed, page: page)
    }

    private struct Token {
        var comparable: String
        var range: Range<String.Index>
    }

    private static func alignedRange(quote: String, page: String) -> Range<String.Index>? {
        let needles = tokens(in: quote).map { term(from: $0.comparable) }
        let haystack = tokens(in: page)
        let width = needles.count
        guard width > 0, haystack.count >= width else { return nil }
        let minimum = width <= 2 ? 1.0 : 0.82
        var bestScore = 0.0
        var best: Range<String.Index>?
        for start in 0...(haystack.count - width) {
            var hits = 0
            for offset in 0..<width where term(from: haystack[start + offset].comparable) == needles[offset] {
                hits += 1
            }
            let score = Double(hits) / Double(width)
            let range = haystack[start].range.lowerBound..<haystack[start + width - 1].range.upperBound
            if score == 1 {
                return range
            }
            if score > bestScore {
                bestScore = score
                best = range
            }
        }
        guard bestScore >= minimum else { return nil }
        return best
    }

    private static func tokens(in text: String) -> [Token] {
        var tokens: [Token] = []
        var wordStart: String.Index?
        var comparable = ""
        var index = text.startIndex

        func commit(at end: String.Index) {
            defer {
                wordStart = nil
                comparable = ""
            }
            guard let wordStart, !comparable.isEmpty else { return }
            tokens.append(Token(comparable: comparable, range: wordStart..<end))
        }

        while index < text.endIndex {
            let character = text[index]
            if isWord(character) {
                if wordStart == nil {
                    wordStart = index
                }
                comparable.append(contentsOf: fold(character))
                index = text.index(after: index)
                continue
            }
            if (character == "," || character == "."),
               wordStart != nil,
               comparable.last?.isNumber == true,
               let digits = thousandsDigits(in: text, after: index) {
                index = digits
                continue
            }
            commit(at: index)
            index = text.index(after: index)
        }
        commit(at: text.endIndex)
        return tokens
    }

    /// Start of a 3-digit thousands group after a comma or period, so "1,500" stays one word and "1, 2025" does not.
    private static func thousandsDigits(in text: String, after separator: String.Index) -> String.Index? {
        var index = text.index(after: separator)
        while index < text.endIndex, text[index].isWhitespace {
            index = text.index(after: index)
        }
        let digitsStart = index
        var digits = 0
        while index < text.endIndex, text[index].isNumber {
            digits += 1
            index = text.index(after: index)
            if digits > 3 { return nil }
        }
        guard digits == 3 else { return nil }
        return digitsStart
    }

    private static func term(from comparable: String) -> String {
        let stripped = comparable.filter { $0 != "$" && $0 != "%" }
        return stripped.isEmpty ? comparable : stripped
    }

    private static func isWord(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "$" || character == "%"
    }

    private static func fold(_ character: Character) -> String {
        String(character)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
    }
}
