import Foundation
import Testing
@testable import DocumentsScanner

struct QuoteSpanTests {
    @Test func anExactPhraseKeepsThePageWording() {
        let page = "Intro. Tenant shall pay rent of $1,500 on the first day. End."
        let parts = QuoteSpan.parts(of: "pay rent of $1,500", in: page)
        #expect(parts?.before == "Intro. Tenant shall ")
        #expect(parts?.match == "pay rent of $1,500")
        #expect(parts?.after == " on the first day. End.")
    }

    @Test func aQuoteWithADifferentCaseStillMarksThePage() {
        let parts = QuoteSpan.parts(of: "RENT", in: "Monthly rent is due.")
        #expect(parts?.match == "rent")
    }

    @Test func thousandsSeparatorsStillFindTheAmount() {
        let page = "Intro. Tenant shall pay rent of $1,500 on the first day. Utilities are separate."
        let parts = QuoteSpan.parts(of: "Tenant shall pay rent of $1500 on the first day.", in: page)
        #expect(parts?.before == "Intro. ")
        #expect(parts?.match == "Tenant shall pay rent of $1,500 on the first day")
        #expect(parts?.after == ". Utilities are separate.")
    }

    @Test func oneDifferentWordStillMarksTheClause() {
        let page = "Tenant shall pay rent of $1,500 on the first day of each month."
        let quote = "Tenant shall pay rent of $1,500 on the fifth day of each month."
        let parts = QuoteSpan.parts(of: quote, in: page)
        #expect(parts?.match == "Tenant shall pay rent of $1,500 on the first day of each month")
    }

    @Test func aMissingPhraseStaysUnmarked() {
        #expect(QuoteSpan.parts(of: "security deposit", in: "Monthly rent is due.") == nil)
    }

    @Test func searchTermsFoldAmountsAndLeaveDatesAlone() {
        #expect(QuoteSpan.terms(in: "Rent is $1,500.") == ["rent", "is", "1500"])
        #expect(QuoteSpan.terms(in: "The term begins October 1, 2025.") == ["the", "term", "begins", "october", "1", "2025"])
        #expect(QuoteSpan.terms(in: "Pi is 3.14.") == ["pi", "is", "3", "14"])
    }
}
