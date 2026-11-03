import Foundation

struct LeaseChecklistAnalyzer: LeaseAnalyzing {
    private let availability: any ModelAvailabilityChecking
    private let generator: any ChecklistGenerating
    private let verifier: QuoteVerifier

    init(
        availability: any ModelAvailabilityChecking,
        generator: any ChecklistGenerating,
        verifier: QuoteVerifier = QuoteVerifier()
    ) {
        self.availability = availability
        self.generator = generator
        self.verifier = verifier
    }

    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading {
        if let early = earlyOutcome(for: document) {
            return LeaseReading(document: document, outcome: early)
        }
        let chunks = LeaseTextChunker.chunks(from: document.pages)
        guard !chunks.isEmpty else {
            return LeaseReading(document: document, outcome: .fallback(.emptyModelAnswer))
        }

        var merged = LeaseChecklist.empty
        var reasons: [FallbackReason] = []
        for (offset, chunk) in chunks.enumerated() {
            try Task.checkCancellation()
            onChunk(offset + 1, chunks.count)
            let (part, reason) = try await collect(chunk, pages: document.pages, allowSplit: true)
            merged = merged.appending(part)
            if let reason {
                reasons.append(reason)
            }
        }

        let checklist = LeaseChecklistMerger.finalize(merged)
        if checklist.isEmpty {
            return LeaseReading(document: document, outcome: .fallback(dominant(reasons)))
        }
        return LeaseReading(document: document, outcome: .checklist(checklist))
    }

    private func earlyOutcome(for document: RecognizedDocument) -> LeaseReading.Outcome? {
        if document.isSparse {
            return .fallback(.sparseText)
        }
        switch availability.readiness() {
        case .available:
            return nil
        case .notReady:
            return .fallback(.modelNotReady)
        case .unavailable:
            return .fallback(.modelUnavailable)
        }
    }

    private func collect(
        _ chunk: LeaseTextChunk,
        pages: [RecognizedPage],
        allowSplit: Bool
    ) async throws -> (LeaseChecklist, FallbackReason?) {
        do {
            let generated = try await generator.generate(from: chunk.prompt)
            return (verifier.verified(generated, pages: pages), nil)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ChecklistGenerationError {
            return try await recover(error, chunk: chunk, pages: pages, allowSplit: allowSplit)
        } catch {
            return (.empty, .modelFailed)
        }
    }

    private func recover(
        _ error: ChecklistGenerationError,
        chunk: LeaseTextChunk,
        pages: [RecognizedPage],
        allowSplit: Bool
    ) async throws -> (LeaseChecklist, FallbackReason?) {
        let reason = reason(for: error)
        guard reason == .contextExceeded, allowSplit, let halves = chunk.halves() else {
            return (.empty, reason)
        }
        let left = try await collect(halves.0, pages: pages, allowSplit: false)
        let right = try await collect(halves.1, pages: pages, allowSplit: false)
        let combined = left.0.appending(right.0)
        if combined.isEmpty {
            return (.empty, left.1 ?? right.1 ?? .contextExceeded)
        }
        return (combined, nil)
    }

    private func reason(for error: ChecklistGenerationError) -> FallbackReason {
        switch error {
        case .refused:
            .modelRefused
        case .contextExceeded:
            .contextExceeded
        case .undecodable:
            .emptyModelAnswer
        case .failed:
            .modelFailed
        }
    }

    private func dominant(_ reasons: [FallbackReason]) -> FallbackReason {
        if reasons.contains(.modelRefused) { return .modelRefused }
        if reasons.contains(.contextExceeded) { return .contextExceeded }
        if reasons.contains(.modelFailed) { return .modelFailed }
        return .emptyModelAnswer
    }
}
