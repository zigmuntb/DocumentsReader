import Foundation

/// A page ready for recognition. Text-layer PDF pages carry `embeddedText` and skip OCR.
struct PreparedPage: Equatable, Sendable {
    let index: Int
    let embeddedText: String?
    let imageData: Data?
}
