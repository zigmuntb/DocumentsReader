import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct ImportViewModelTests {
    @Test func copiedFileStartsAJob() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try Data("%PDF-".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let session = InMemoryDocumentSessionStore()
        let viewModel = ImportViewModel(session: session)
        var event: ImportEvent?
        viewModel.onEvent = { event = $0 }
        viewModel.receive(.success([url]))

        guard case .ready(let id) = event else {
            Issue.record("Expected a ready import")
            return
        }
        let job = session.job(id: id)
        guard let job else {
            Issue.record("Expected a staged file")
            return
        }
        guard case .file = job.pages.first else {
            Issue.record("Expected a staged file")
            return
        }
    }

    @Test func cancellationIsQuiet() {
        let viewModel = ImportViewModel(session: InMemoryDocumentSessionStore())
        var events: [ImportEvent] = []
        viewModel.onEvent = { events.append($0) }
        viewModel.receive(.failure(CocoaError(.userCancelled)))
        #expect(events.isEmpty)
    }
}
