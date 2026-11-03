import Foundation

enum LeaseChecklistMerger {
    static let questionLimit = 5

    static func finalize(_ checklist: LeaseChecklist) -> LeaseChecklist {
        LeaseChecklist(
            parties: unique(checklist.parties),
            money: unique(checklist.money),
            dates: unique(checklist.dates),
            obligations: unique(checklist.obligations),
            questionsBeforeSigning: Array(unique(checklist.questionsBeforeSigning).prefix(questionLimit))
        )
    }

    private static func unique(_ items: [ChecklistItem]) -> [ChecklistItem] {
        var seen: Set<String> = []
        return items.filter { item in
            let key = QuoteText.comparable(item.quote)
            guard !key.isEmpty else { return false }
            return seen.insert(key).inserted
        }
    }
}
