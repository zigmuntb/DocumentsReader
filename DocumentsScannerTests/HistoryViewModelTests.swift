import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct HistoryViewModelTests {
    @Test func anEmptyArchiveShowsTheEmptyState() {
        let model = HistoryViewModel(session: InMemoryDocumentSessionStore())
        #expect(model.state == .empty)
    }

    @Test func aSavedLeaseCanBeOpened() throws {
        let store = InMemoryDocumentSessionStore()
        let id = UUID()
        store.save(
            LeaseReading(
                document: RecognizedDocument(
                    id: id,
                    pages: [RecognizedPage(index: 0, text: "Residential lease")],
                    isSparse: false
                ),
                outcome: .fallback(.modelUnavailable)
            )
        )
        let model = HistoryViewModel(session: store)
        guard case .loaded(let entries) = model.state else {
            Issue.record("The saved lease should be listed")
            return
        }
        #expect(entries.map(\.id) == [id])
        #expect(entries.first?.summary == .textOnly)
        var opened: [HistoryEvent] = []
        model.onEvent = { opened.append($0) }
        model.select(entries[0])
        #expect(opened == [.open(id)])
    }

    @Test func anUnreadableArchiveShowsTheFailure() {
        let model = HistoryViewModel(session: UnreadableHistoryStore())
        #expect(model.state == .failed)
    }
}

@MainActor
private final class UnreadableHistoryStore: DocumentSessionStoring {
    func stage(_ job: RecognitionJob) -> UUID { UUID() }
    func job(id: UUID) -> RecognitionJob? { nil }
    func save(_ document: RecognizedDocument) {}
    func document(id: UUID) -> RecognizedDocument? { nil }
    func save(_ reading: LeaseReading) {}
    func reading(id: UUID) -> LeaseReading? { nil }
    func history() throws -> [LeaseHistoryEntry] { throw HistoryStoreError.unreadable }
}
