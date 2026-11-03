import Foundation
import Testing
@testable import DocumentsScanner

struct LeaseChecklistAnalyzerTests {
    @Test func sparseTextSkipsTheModel() async throws {
        let reading = try await analyze(
            document(text: "rent", sparse: true),
            generator: FailingGenerator()
        )
        #expect(reading.outcome == .fallback(.sparseText))
    }

    @Test func unavailableModelSkipsGeneration() async throws {
        let reading = try await analyze(
            lease(),
            availability: .unavailable,
            generator: FailingGenerator()
        )
        #expect(reading.outcome == .fallback(.modelUnavailable))
    }

    @Test func modelNotReadySkipsGeneration() async throws {
        let reading = try await analyze(
            lease(),
            availability: .notReady,
            generator: FailingGenerator()
        )
        #expect(reading.outcome == .fallback(.modelNotReady))
    }

    @Test func verifiedQuotesAreKeptAndDuplicatesDrop() async throws {
        let quote = "Tenant shall pay rent of $1500 on the first day of each month."
        let reading = try await analyze(
            lease(text: quote),
            generator: FixedGenerator(checklist: checklist(money: [
                item(title: "Rent", quote: quote),
                item(title: "Rent again", quote: quote)
            ]))
        )
        guard case .checklist(let list) = reading.outcome else {
            Issue.record("Expected a checklist")
            return
        }
        #expect(list.money.map(\.title) == ["Rent"])
    }

    @Test func inventedQuotesBecomeTheEmptyFallback() async throws {
        let reading = try await analyze(
            lease(),
            generator: FixedGenerator(checklist: checklist(money: [
                item(title: "Deposit", quote: "The landlord may keep every deposit forever.")
            ]))
        )
        #expect(reading.outcome == .fallback(.emptyModelAnswer))
    }

    @Test func anEmptyAnswerUsesTheFixedQuestions() async throws {
        let reading = try await analyze(lease(), generator: FixedGenerator(checklist: .empty))
        #expect(reading.outcome == .fallback(.emptyModelAnswer))
    }

    @Test func aRefusalUsesTheFixedQuestions() async throws {
        let reading = try await analyze(lease(), generator: ThrowingGenerator(.refused))
        #expect(reading.outcome == .fallback(.modelRefused))
    }

    @Test func questionsStopAtFive() async throws {
        let quotes = (0..<6).map { "Obligation number \($0) is written in the lease." }
        let questions = quotes.enumerated().map { index, quote in
            item(title: "Question \(index)", quote: quote)
        }
        let reading = try await analyze(
            lease(text: quotes.joined(separator: " ")),
            generator: FixedGenerator(
                checklist: LeaseChecklist(
                    parties: [],
                    money: [],
                    dates: [],
                    obligations: [],
                    questionsBeforeSigning: questions
                )
            )
        )
        guard case .checklist(let list) = reading.outcome else {
            Issue.record("Expected a checklist")
            return
        }
        #expect(list.questionsBeforeSigning.map(\.title) == (0..<5).map { "Question \($0)" })
    }

    @Test func aLaterPartSurvivesAnEarlierRefusal() async throws {
        let quote = "Tenant shall pay rent of $1500 on the first day of each month."
        let text = quote + " " + String(repeating: "word ", count: 400)
        let reading = try await analyze(
            lease(text: text),
            generator: FirstPartRefusesGenerator(
                success: checklist(money: [item(title: "Rent", quote: quote)])
            )
        )
        guard case .checklist(let list) = reading.outcome else {
            Issue.record("Expected a checklist")
            return
        }
        #expect(list.money.map(\.title) == ["Rent"])
    }

    @Test func aContextOverflowSplitsOnceAndKeepsTheFact() async throws {
        let quote = "Tenant shall pay rent of $1500 on the first day of each month."
        let text = quote + " " + String(repeating: "clause ", count: 120)
        let reading = try await analyze(
            lease(text: text),
            generator: LengthGateGenerator(
                limit: 700,
                success: checklist(money: [item(title: "Rent", quote: quote)])
            )
        )
        guard case .checklist(let list) = reading.outcome else {
            Issue.record("Expected a checklist")
            return
        }
        #expect(list.money.map(\.title) == ["Rent"])
    }

    @Test func leavingCancelsTheAnalysis() async {
        let analyzer = LeaseChecklistAnalyzer(
            availability: FixedAvailability(value: .available),
            generator: SleepingGenerator()
        )
        let task = Task {
            try await analyzer.analyze(lease()) { _, _ in }
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    private func analyze(
        _ document: RecognizedDocument,
        availability: ModelReadiness = .available,
        generator: any ChecklistGenerating
    ) async throws -> LeaseReading {
        let analyzer = LeaseChecklistAnalyzer(
            availability: FixedAvailability(value: availability),
            generator: generator
        )
        return try await analyzer.analyze(document) { _, _ in }
    }

    private func lease(text: String = "Tenant shall pay rent of $1500 on the first day of each month.") -> RecognizedDocument {
        document(text: text, sparse: false)
    }

    private func document(text: String, sparse: Bool) -> RecognizedDocument {
        RecognizedDocument(
            id: UUID(),
            pages: [RecognizedPage(index: 0, text: text)],
            isSparse: sparse
        )
    }

    private func item(title: String, quote: String) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            title: title,
            plainExplanation: "Plain words.",
            quote: quote,
            pageIndex: 0,
            severity: .check
        )
    }

    private func checklist(money: [ChecklistItem]) -> LeaseChecklist {
        LeaseChecklist(
            parties: [],
            money: money,
            dates: [],
            obligations: [],
            questionsBeforeSigning: []
        )
    }
}

private struct FixedAvailability: ModelAvailabilityChecking {
    var value: ModelReadiness
    func readiness() -> ModelReadiness { value }
}

private struct FailingGenerator: ChecklistGenerating {
    func generate(from prompt: String) async throws -> LeaseChecklist {
        throw ChecklistGenerationError.failed
    }
}

private struct FixedGenerator: ChecklistGenerating {
    var checklist: LeaseChecklist
    func generate(from prompt: String) async throws -> LeaseChecklist { checklist }
}

private struct ThrowingGenerator: ChecklistGenerating {
    var error: ChecklistGenerationError
    init(_ error: ChecklistGenerationError) { self.error = error }
    func generate(from prompt: String) async throws -> LeaseChecklist { throw error }
}

private struct LengthGateGenerator: ChecklistGenerating {
    var limit: Int
    var success: LeaseChecklist
    func generate(from prompt: String) async throws -> LeaseChecklist {
        if prompt.count > limit {
            throw ChecklistGenerationError.contextExceeded
        }
        return success
    }
}

private struct SleepingGenerator: ChecklistGenerating {
    func generate(from prompt: String) async throws -> LeaseChecklist {
        try await Task.sleep(for: .seconds(5))
        return .empty
    }
}

private struct FirstPartRefusesGenerator: ChecklistGenerating {
    var success: LeaseChecklist

    func generate(from prompt: String) async throws -> LeaseChecklist {
        if prompt.count > 1_000 {
            throw ChecklistGenerationError.refused
        }
        return success
    }
}
