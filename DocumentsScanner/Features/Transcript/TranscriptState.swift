import Foundation

struct TranscriptContent: Equatable {
    let document: RecognizedDocument
    let fallback: FallbackReason?
}

enum TranscriptState: Equatable {
    case missing
    case loaded(TranscriptContent)
}
