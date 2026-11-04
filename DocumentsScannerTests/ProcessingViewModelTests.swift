import CoreGraphics
import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct ProcessingViewModelTests {
    @Test func finishedReadingSavesTheDocument() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let text = String(repeating: "a", count: LeaseTextLimits.minimumUsefulCharacters)
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(pages: [RecognizedPage(index: 0, text: text)]),
            analyzer: ImmediateFallbackAnalyzer()
        )
        var finished: UUID?
        viewModel.onEvent = { event in
            if case .finished(let documentID) = event {
                finished = documentID
            }
        }

        await viewModel.run()

        #expect(finished == id)
        #expect(session.document(id: id)?.isSparse == false)
    }

    @Test func shortTextIsSavedAsSparse() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(pages: [RecognizedPage(index: 0, text: "rent")]),
            analyzer: ImmediateFallbackAnalyzer()
        )
        var finished = false
        viewModel.onEvent = { _ in finished = true }

        await viewModel.run()

        #expect(finished)
        #expect(session.document(id: id)?.isSparse == true)
    }

    @Test func emptyTextStaysOnTheFailure() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(pages: [RecognizedPage(index: 0, text: "...")]),
            analyzer: ImmediateFallbackAnalyzer()
        )
        var finished = false
        viewModel.onEvent = { _ in finished = true }

        await viewModel.run()

        #expect(finished == false)
        #expect(viewModel.phase == .failed(.noText))
    }

    @Test func recognitionErrorFailsWithoutSaving() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(error: DocumentReadError.recognitionFailed),
            analyzer: ImmediateFallbackAnalyzer()
        )

        await viewModel.run()

        #expect(viewModel.phase == .failed(.failed))
        #expect(session.document(id: id) == nil)
    }

    @Test func leavingCancelsBeforeADocumentIsSaved() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: SlowRecognizer(),
            analyzer: ImmediateFallbackAnalyzer()
        )
        let task = Task { await viewModel.run() }
        task.cancel()
        await task.value
        #expect(session.document(id: id) == nil)
    }

    @Test func checklistReadingIsSavedWhenAnalysisAgrees() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let quote = String(repeating: "a", count: LeaseTextLimits.minimumUsefulCharacters)
        let item = ChecklistItem(
            id: UUID(),
            title: "Term",
            plainExplanation: "A term.",
            quote: quote,
            pageIndex: 0,
            severity: .ok
        )
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(pages: [RecognizedPage(index: 0, text: quote)]),
            analyzer: FixedReadingAnalyzer(
                outcome: .checklist(
                    LeaseChecklist(
                        parties: [item],
                        money: [],
                        dates: [],
                        obligations: [],
                        questionsBeforeSigning: []
                    )
                )
            )
        )

        await viewModel.run()

        guard case .checklist(let checklist) = session.reading(id: id)?.outcome else {
            Issue.record("Expected a checklist")
            return
        }
        #expect(checklist.parties.map(\.title) == ["Term"])
    }

    @Test func leavingDuringTheCheckSavesNothing() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: ScriptedRecognizer(pages: [RecognizedPage(index: 0, text: String(repeating: "a", count: 40))]),
            analyzer: SleepingAnalyzer()
        )
        var finished = false
        viewModel.onEvent = { _ in finished = true }
        let task = Task { await viewModel.run() }
        task.cancel()
        await task.value
        #expect(finished == false)
        #expect(session.document(id: id) == nil)
        #expect(session.reading(id: id) == nil)
    }

    @Test func livePageKeepsTheLinesBeingRead() async {
        let session = InMemoryDocumentSessionStore()
        let id = session.stage(.pages([.image(Data([1]))]))
        let line = ScanLine(
            index: 0,
            text: "Rent is due",
            bounds: CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.04)
        )
        let viewModel = ProcessingViewModel(
            documentID: id,
            session: session,
            recognizer: LineRecognizer(line: line),
            analyzer: ImmediateFallbackAnalyzer()
        )

        await viewModel.run(reduceMotion: true)

        #expect(viewModel.livePage?.lines.map(\.text) == ["Rent is due"])
        #expect(viewModel.livePage?.activity == .readingLines)
    }
}

private struct ScriptedRecognizer: TextRecognizing {
    var pages: [RecognizedPage] = []
    var error: Error?

    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage] {
        if let error { throw error }
        onPage(ScanFrame(
            pageIndex: 0,
            pageCount: max(pages.count, 1),
            imageJPEG: nil,
            lines: [],
            activity: .sweeping
        ))
        return pages
    }
}

private struct LineRecognizer: TextRecognizing {
    let line: ScanLine

    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage] {
        onPage(ScanFrame(
            pageIndex: 0,
            pageCount: 1,
            imageJPEG: Data([9]),
            lines: [line],
            activity: .readingLines
        ))
        await Task.yield()
        return [RecognizedPage(index: 0, text: line.text)]
    }
}

private struct SlowRecognizer: TextRecognizing {
    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage] {
        try await Task.sleep(for: .milliseconds(400))
        try Task.checkCancellation()
        return [RecognizedPage(index: 0, text: "hello")]
    }
}

private struct ImmediateFallbackAnalyzer: LeaseAnalyzing {
    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading {
        LeaseReading(document: document, outcome: .fallback(.modelUnavailable))
    }
}

private struct FixedReadingAnalyzer: LeaseAnalyzing {
    var outcome: LeaseReading.Outcome
    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading {
        LeaseReading(document: document, outcome: outcome)
    }
}

private struct SleepingAnalyzer: LeaseAnalyzing {
    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading {
        try await Task.sleep(for: .seconds(2))
        return LeaseReading(document: document, outcome: .fallback(.modelUnavailable))
    }
}
