import Foundation

enum SigningQuestionTemplate {
    static var questions: [String] {
        [
            String(localized: "Who are the parties, and are the names spelled the way you expect?"),
            String(localized: "How much is due, when, and what happens if it is late?"),
            String(localized: "When does the lease start and end, and how do you leave?"),
            String(localized: "What must you repair, insure, or pay for besides the rent?"),
            String(localized: "What did you want changed, and is that change written in this document?")
        ]
    }
}
