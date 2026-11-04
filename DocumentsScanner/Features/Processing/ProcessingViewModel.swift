import Foundation
import Observation

@MainActor
@Observable
final class ProcessingViewModel {
    var onEvent: (ProcessingEvent) -> Void = { _ in }
    private(set) var phase: ProcessingPhase = .idle
    /// The page on screen. Line reveals can lag the recognizer by one page so the lift can finish.
    private(set) var livePage: ScanFrame?

    private let documentID: UUID
    private let session: any DocumentSessionStoring
    private let recognizer: any TextRecognizing
    private let analyzer: any LeaseAnalyzing
    private var generation = UUID()
    private var reduceMotion = false
    private var pendingFrames: [ScanFrame] = []
    private var revealHold: Task<Void, Never>?

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

    func run(reduceMotion: Bool = false) async {
        switch phase {
        case .reading, .checking:
            return
        case .idle, .failed:
            break
        }
        let generation = UUID()
        self.generation = generation
        self.reduceMotion = reduceMotion
        cancelReveal()
        livePage = nil
        phase = .reading(completed: 0, total: 0)

        guard let job = session.job(id: documentID) else {
            phase = .failed(.unreadable)
            return
        }
        prime(job)

        do {
            let pages = try await recognizer.recognize(job) { [weak self] frame in
                self?.deliver(frame, generation: generation)
            }
            try Task.checkCancellation()
            guard generation == self.generation else { return }
            try await finishRevealQueue(generation: generation)
            guard generation == self.generation else { return }
            try await finish(pages, generation: generation)
        } catch is CancellationError {
            cancelReveal()
            return
        } catch DocumentReadError.unreadableFile, DocumentReadError.noPages {
            guard generation == self.generation else { return }
            cancelReveal()
            phase = .failed(.unreadable)
        } catch {
            guard generation == self.generation else { return }
            cancelReveal()
            phase = .failed(.failed)
        }
    }

    /// Puts the first scanned photo on screen before recognition starts.
    private func prime(_ job: RecognitionJob) {
        let images = job.pages.compactMap { payload -> Data? in
            if case .image(let data) = payload, !data.isEmpty { return data }
            return nil
        }
        guard let first = images.first else { return }
        livePage = ScanFrame(
            pageIndex: 0,
            pageCount: images.count,
            imageJPEG: first,
            lines: [],
            activity: .sweeping
        )
        phase = .reading(completed: 0, total: images.count)
    }

    /// Applies a frame on the main actor now, so the page is visible while OCR runs.
    private nonisolated func deliver(_ frame: ScanFrame, generation: UUID) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.show(frame, generation: generation)
            }
        } else {
            Task { @MainActor in
                self.show(frame, generation: generation)
            }
        }
    }

    private func show(_ frame: ScanFrame, generation: UUID) {
        guard self.generation == generation else { return }
        guard case .reading = phase else { return }
        if revealHold != nil {
            enqueue(frame)
            return
        }
        play(frame, generation: generation)
    }

    private func enqueue(_ frame: ScanFrame) {
        if frame.activity == .readingLines {
            pendingFrames.removeAll { $0.pageIndex == frame.pageIndex && $0.activity == .sweeping }
        }
        pendingFrames.append(frame)
    }

    private func play(_ frame: ScanFrame, generation: UUID) {
        guard self.generation == generation else { return }
        guard case .reading = phase else { return }
        livePage = frame
        let completed = frame.activity == .readingLines ? frame.pageIndex + 1 : frame.pageIndex
        phase = .reading(completed: completed, total: frame.pageCount)
        guard !reduceMotion, frame.activity == .readingLines else { return }

        let duration = ScanTiming.liftDuration(lineCount: frame.lines.count)
        revealHold = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, !Task.isCancelled else { return }
            self.revealHold = nil
            guard self.generation == generation else { return }
            guard case .reading = self.phase else { return }
            guard let next = self.pendingFrames.first else { return }
            self.pendingFrames.removeFirst()
            self.play(next, generation: generation)
        }
    }

    private func finishRevealQueue(generation: UUID) async throws {
        while revealHold != nil || !pendingFrames.isEmpty {
            try Task.checkCancellation()
            guard self.generation == generation else { return }
            if let hold = revealHold {
                await hold.value
                continue
            }
            guard let next = pendingFrames.first else { return }
            pendingFrames.removeFirst()
            play(next, generation: generation)
        }
    }

    private func cancelReveal() {
        revealHold?.cancel()
        revealHold = nil
        pendingFrames.removeAll()
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
