import Foundation

enum QuoteText {
    /// Lowercase, unwrap line breaks, and drop punctuation so an OCR hyphen or a stray comma can still match.
    static func comparable(_ text: String) -> String {
        let normalized = LeaseTextNormalizer.normalize(text).lowercased()
        var words: [String] = []
        var word = ""
        for character in normalized {
            if character.isLetter || character.isNumber || character == "$" || character == "%" {
                word.append(character)
            } else if !word.isEmpty {
                words.append(word)
                word = ""
            }
        }
        if !word.isEmpty {
            words.append(word)
        }
        return words.joined(separator: " ")
    }
}
