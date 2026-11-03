import Foundation

struct RecognitionJob: Equatable, Sendable {
    let pages: [PagePayload]

    static func pages(_ pages: [PagePayload]) -> RecognitionJob {
        RecognitionJob(pages: pages)
    }
}
