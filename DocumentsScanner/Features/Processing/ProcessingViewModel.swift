import Foundation
import Observation

@MainActor
@Observable
final class ProcessingViewModel {
    var onEvent: (ProcessingEvent) -> Void = { _ in }
    private(set) var phase: ProcessingPhase = .idle

    private let documentID: UUID
    private let session: any DocumentSessionStoring
    private let recognizer: any TextRecognizing
    private let analyzer: any LeaseAnalyzing
    private var generation = UUID()

    init(
        documentID: UUID,
        session: any DocumentSessionStoring,
        recognizer: any TextRecognizing,
        analyzer: any LeaseAnalyzing
    ) {
        self.documentID = documentID
        self.session = session
        self.recognizer = recognizer
        self.analyzer = analyzer
    }

    func run() async {
        switch phase {
        case .reading, .checking:
            return
        case .idle, .failed:
            break
        }
        let generation = UUID()
        self.generation = generation
        phase = .reading(completed: 0, total: 0)

        guard let job = session.job(id: documentID) else {
            phase = .failed(.unreadable)
            return
        }

        do {
            let pages = try await recognizer.recognize(job) { [weak self] completed, total in
                Task { @MainActor in
                    guard let self, self.generation == generation else { return }
                    guard case .reading = self.phase else { return }
                    self.phase = .reading(completed: completed, total: total)
                }
            }
            try Task.checkCancellation()
            guard generation == self.generation else { return }
            try await finish(pages, generation: generation)
        } catch is CancellationError {
            return
        } catch DocumentReadError.unreadableFile, DocumentReadError.noPages {
            guard generation == self.generation else { return }
            phase = .failed(.unreadable)
        } catch {
            guard generation == self.generation else { return }
            phase = .failed(.failed)
        }
    }

    private func finish(_ pages: [RecognizedPage], generation: UUID) async throws {
        try Task.checkCancellation()
        guard generation == self.generation else { return }
        let count = LeaseTextLimits.usefulCharacterCount(in: pages)
        guard count > 0 else {
            phase = .failed(.noText)
            return
        }
        let document = RecognizedDocument(
            id: documentID,
            pages: pages,
            isSparse: count < LeaseTextLimits.minimumUsefulCharacters
        )
        phase = .checking(completed: 0, total: 0)
        let reading = try await analyzer.analyze(document) { [weak self] completed, total in
            Task { @MainActor in
                guard let self, self.generation == generation else { return }
                guard case .checking = self.phase else { return }
                self.phase = .checking(completed: completed, total: total)
            }
        }
        try Task.checkCancellation()
        guard generation == self.generation else { return }
        session.save(document)
        session.save(reading)
        onEvent(.finished(documentID))
    }
}
