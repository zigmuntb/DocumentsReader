import Foundation
import FoundationModels

@Generable(description: "One fact copied from a lease excerpt.")
struct GeneratedChecklistItem {
    @Guide(description: "A short name for the fact, in plain words.")
    var title: String

    @Guide(description: "One or two simple sentences. No legal advice.")
    var plainExplanation: String

    @Guide(description: "Words copied exactly from the excerpt.")
    var quote: String

    @Guide(description: "The page index printed above the quote.", .range(0...40))
    var pageIndex: Int

    @Guide(description: "ok when the term is ordinary, check when it is unusual or one-sided.", .anyOf(["ok", "check"]))
    var severity: String
}

@Generable(description: "Facts stated in one lease excerpt.")
struct GeneratedChecklist {
    @Guide(description: "People or companies named as parties. Empty if this excerpt names none.")
    var parties: [GeneratedChecklistItem]

    @Guide(description: "Rent, deposits, fees, and other amounts. Empty if this excerpt states none.")
    var money: [GeneratedChecklistItem]

    @Guide(description: "Start, end, notice, and other dates. Empty if this excerpt states none.")
    var dates: [GeneratedChecklistItem]

    @Guide(description: "Duties of either party. Empty if this excerpt states none.")
    var obligations: [GeneratedChecklistItem]

    @Guide(description: "Questions to answer before signing, each tied to a quote in this excerpt.", .maximumCount(5))
    var questionsBeforeSigning: [GeneratedChecklistItem]
}
