import Foundation

struct LeaseReading: Equatable, Sendable {
    let document: RecognizedDocument
    let outcome: Outcome

    enum Outcome: Equatable, Sendable {
        case checklist(LeaseChecklist)
        case fallback(FallbackReason)
    }
}
