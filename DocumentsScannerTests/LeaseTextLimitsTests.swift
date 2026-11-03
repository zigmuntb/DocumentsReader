import Foundation
import Testing
@testable import DocumentsScanner

struct LeaseTextLimitsTests {
    @Test func countsLettersAndDigitsOnly() {
        let pages = [RecognizedPage(index: 0, text: "Rent $50.")]
        #expect(LeaseTextLimits.usefulCharacterCount(in: pages) == 6)
    }
}
