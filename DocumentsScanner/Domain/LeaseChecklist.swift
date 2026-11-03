import Foundation

struct LeaseChecklist: Equatable, Sendable {
    var parties: [ChecklistItem]
    var money: [ChecklistItem]
    var dates: [ChecklistItem]
    var obligations: [ChecklistItem]
    var questionsBeforeSigning: [ChecklistItem]

    static let empty = LeaseChecklist(
        parties: [],
        money: [],
        dates: [],
        obligations: [],
        questionsBeforeSigning: []
    )

    var isEmpty: Bool {
        parties.isEmpty && money.isEmpty && dates.isEmpty && obligations.isEmpty && questionsBeforeSigning.isEmpty
    }

    func item(id: UUID) -> ChecklistItem? {
        let items = parties + money + dates + obligations + questionsBeforeSigning
        return items.first { $0.id == id }
    }

    func appending(_ other: LeaseChecklist) -> LeaseChecklist {
        LeaseChecklist(
            parties: parties + other.parties,
            money: money + other.money,
            dates: dates + other.dates,
            obligations: obligations + other.obligations,
            questionsBeforeSigning: questionsBeforeSigning + other.questionsBeforeSigning
        )
    }
}
