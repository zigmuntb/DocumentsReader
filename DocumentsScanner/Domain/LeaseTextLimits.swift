import Foundation

enum LeaseTextLimits {
    /// A couple of words is not a lease. Shorter text still opens, marked sparse; empty text does not.
    static let minimumUsefulCharacters = 40

    static func usefulCharacterCount(in pages: [RecognizedPage]) -> Int {
        pages.reduce(0) { total, page in
            total + page.text.unicodeScalars.reduce(0) { count, scalar in
                CharacterSet.alphanumerics.contains(scalar) ? count + 1 : count
            }
        }
    }
}
