import Foundation
import Testing
@testable import DocumentsScanner

struct QuoteVerifierTests {
    private let verifier = QuoteVerifier()

    @Test func exactQuoteIsKept() {
        let quote = "Tenant shall pay rent of $1500 on the first day."
        let kept = verifier.verified([item(quote: quote)], pages: [page(0, quote)])
        #expect(kept.map(\.quote) == [quote])
        #expect(kept.map(\.pageIndex) == [0])
    }

    @Test func hyphenatedLineBreakStillMatches() {
        let pageText = "The ten-\nant shall pay rent of $1500."
        let quote = "The tenant shall pay rent of $1500."
        let kept = verifier.verified([item(quote: quote)], pages: [page(0, pageText)])
        #expect(kept.map(\.quote) == [quote])
    }

    @Test func oneCharacterOcrErrorStillMatches() {
        let pageText = "The tenant shall pay a late fee of fifty dollars."
        let quote = "The tenant shall pay a late fe of fifty dollars."
        let kept = verifier.verified([item(quote: quote)], pages: [page(0, pageText)])
        #expect(kept.count == 1)
    }

    @Test func inventedQuoteIsDropped() {
        let pageText = "The tenant shall pay a late fee of fifty dollars."
        let quote = "Zebra balloons orbit quietly over frozen lakes."
        let kept = verifier.verified([item(quote: quote)], pages: [page(0, pageText)])
        #expect(kept.isEmpty)
    }

    @Test func emptyQuoteIsDropped() {
        let kept = verifier.verified(
            [item(title: "Rent", quote: "   ")],
            pages: [page(0, "Tenant shall pay rent.")]
        )
        #expect(kept.isEmpty)
    }

    @Test func quoteFoundOnAnotherPageCorrectsTheIndex() {
        let quote = "Tenant shall pay rent of $1500 on the first day."
        let pages = [
            page(0, "Cover page of the lease agreement."),
            page(1, quote)
        ]
        let kept = verifier.verified([item(quote: quote, page: 0)], pages: pages)
        #expect(kept.map(\.pageIndex) == [1])
    }

    @Test func unknownSeverityStaysOnCheck() {
        #expect(ChecklistSeverity.resolved(from: " OK ") == .ok)
        #expect(ChecklistSeverity.resolved(from: "maybe") == .check)
    }

    private func page(_ index: Int, _ text: String) -> RecognizedPage {
        RecognizedPage(index: index, text: text)
    }

    private func item(title: String = "Rent", quote: String, page: Int = 0) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            title: title,
            plainExplanation: "Plain words.",
            quote: quote,
            pageIndex: page,
            severity: .check
        )
    }
}
