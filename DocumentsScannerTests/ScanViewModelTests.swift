import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct ScanViewModelTests {
    @Test func pagesAreStagedAndFinished() {
        let session = InMemoryDocumentSessionStore()
        let viewModel = ScanViewModel(session: session)
        var event: ScanEvent?
        viewModel.onEvent = { event = $0 }

        viewModel.didScan(pages: [Data([1, 2]), Data()])

        guard case .finished(let id) = event else {
            Issue.record("Expected a finished scan")
            return
        }
        #expect(session.job(id: id)?.pages == [.image(Data([1, 2]))])
    }

    @Test func emptyScanFails() {
        let viewModel = ScanViewModel(session: InMemoryDocumentSessionStore())
        var event: ScanEvent?
        viewModel.onEvent = { event = $0 }
        viewModel.didScan(pages: [])
        #expect(event == .failed)
    }
}
