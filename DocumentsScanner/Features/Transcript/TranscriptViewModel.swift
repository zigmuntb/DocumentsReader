import Foundation
import Observation

@MainActor
@Observable
final class TranscriptViewModel {
    private(set) var state: TranscriptState

    init(documentID: UUID, session: any DocumentSessionStoring) {
        if let document = session.document(id: documentID) {
            let fallback: FallbackReason?
            if case .fallback(let reason) = session.reading(id: documentID)?.outcome {
                fallback = reason
            } else {
                fallback = nil
            }
            state = .loaded(TranscriptContent(document: document, fallback: fallback))
        } else {
            state = .missing
        }
    }
}
