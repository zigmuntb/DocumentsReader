import Foundation

/// OCR keeps one visual line per newline. Those wraps become spaces; a blank line stays a paragraph.
/// A hyphen that exists only to break a word across lines is removed. Digits are left alone so "5-\n10" does not become "510".
enum LeaseTextNormalizer {
    static func normalize(_ raw: String) -> String {
        var text = raw.precomposedStringWithCanonicalMapping
        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        text = text.replacingOccurrences(of: "\u{00AD}", with: "")
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "\r", with: "\n")
        text = joinHyphenatedLineBreaks(text)

        var paragraphs: [String] = []
        var current: [String] = []

        func flush() {
            let joined = current.joined(separator: " ")
            let collapsed = joined.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            if !collapsed.isEmpty {
                paragraphs.append(collapsed)
            }
            current.removeAll()
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flush()
            } else {
                current.append(String(trimmed))
            }
        }
        flush()
        return paragraphs.joined(separator: "\n\n")
    }

    private static func joinHyphenatedLineBreaks(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "-", let joined = skipHyphenBreak(in: text, hyphen: index, written: result) {
                result.append(contentsOf: joined.kept)
                index = joined.resume
                continue
            }
            result.append(text[index])
            index = text.index(after: index)
        }
        return result
    }

    private static func skipHyphenBreak(
        in text: String,
        hyphen: String.Index,
        written: String
    ) -> (kept: String, resume: String.Index)? {
        var cursor = text.index(after: hyphen)
        cursor = skipSpaces(in: text, from: cursor)
        guard cursor < text.endIndex, text[cursor] == "\n" else { return nil }
        var afterNewline = text.index(after: cursor)
        afterNewline = skipSpaces(in: text, from: afterNewline)
        let previousIsLetter = written.last?.isLetter == true
        let nextIsLetter = afterNewline < text.endIndex && text[afterNewline].isLetter
        guard previousIsLetter, nextIsLetter else { return nil }
        return ("", afterNewline)
    }

    private static func skipSpaces(in text: String, from index: String.Index) -> String.Index {
        var cursor = index
        while cursor < text.endIndex, text[cursor] == " " || text[cursor] == "\t" {
            cursor = text.index(after: cursor)
        }
        return cursor
    }
}
