import Foundation

struct RecognizedDocument: Equatable, Sendable, Identifiable {
    let id: UUID
    let pages: [RecognizedPage]
    /// Below the useful-text threshold. The transcript still shows what was read.
    let isSparse: Bool
}
