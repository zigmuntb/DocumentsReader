import Foundation

struct RecognizedPage: Equatable, Sendable, Identifiable {
    let index: Int
    let text: String

    var id: Int { index }
}
