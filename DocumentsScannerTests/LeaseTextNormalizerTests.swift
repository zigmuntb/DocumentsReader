import Foundation
import Testing
@testable import DocumentsScanner

struct LeaseTextNormalizerTests {
    @Test func joinsAWordBrokenAcrossALine() {
        #expect(LeaseTextNormalizer.normalize("pay-\nment") == "payment")
    }

    @Test func joinsWhenTheBreakHasSpaces() {
        #expect(LeaseTextNormalizer.normalize("pay- \nment") == "payment")
    }

    @Test func keepsAHyphenThatIsNotALineBreak() {
        #expect(LeaseTextNormalizer.normalize("state-of-the-art") == "state-of-the-art")
    }

    @Test func doesNotGlueNumbers() {
        #expect(LeaseTextNormalizer.normalize("5-\n10") == "5- 10")
    }

    @Test func unwrapsVisualLinesAndKeepsParagraphs() {
        let raw = "line one\nline two\n\npara two"
        #expect(LeaseTextNormalizer.normalize(raw) == "line one line two\n\npara two")
    }

    @Test func collapsesExtraSpaces() {
        #expect(LeaseTextNormalizer.normalize("  a \t b  ") == "a b")
    }

    @Test func normalizesWindowsBreaksSoftHyphensAndNonBreakingSpaces() {
        let raw = "pay\u{00AD}ment\r\n is\u{00A0}due"
        #expect(LeaseTextNormalizer.normalize(raw) == "payment is due")
    }

    @Test func emptyInputStaysEmpty() {
        #expect(LeaseTextNormalizer.normalize("  \n\n  ").isEmpty)
    }
}
