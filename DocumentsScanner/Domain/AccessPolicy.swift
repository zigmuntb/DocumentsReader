import Foundation

struct AccessPolicy: Sendable {
    static let freeItemLimit = 2

    func present(_ checklist: LeaseChecklist, hasPro: Bool) -> ChecklistPresentation {
        let openIDs = openIdentifiers(in: checklist, hasPro: hasPro)
        let sections = ChecklistSectionKind.allCases.compactMap { kind -> ChecklistPresentation.Section? in
            let rows = items(kind, in: checklist).map { item in
                openIDs.contains(item.id) ? ChecklistRow.open(item) : ChecklistRow.locked(item.id)
            }
            guard !rows.isEmpty else { return nil }
            return ChecklistPresentation.Section(kind: kind, rows: rows)
        }
        return ChecklistPresentation(sections: sections)
    }

    func isOpen(_ itemID: UUID, in checklist: LeaseChecklist, hasPro: Bool) -> Bool {
        openIdentifiers(in: checklist, hasPro: hasPro).contains(itemID)
    }

    private func openIdentifiers(in checklist: LeaseChecklist, hasPro: Bool) -> Set<UUID> {
        let ordered = ordered(checklist)
        if hasPro {
            return Set(ordered.map(\.id))
        }
        return Set(ordered.prefix(Self.freeItemLimit).map(\.id))
    }

    private func ordered(_ checklist: LeaseChecklist) -> [ChecklistItem] {
        checklist.parties
            + checklist.money
            + checklist.dates
            + checklist.obligations
            + checklist.questionsBeforeSigning
    }

    private func items(_ kind: ChecklistSectionKind, in checklist: LeaseChecklist) -> [ChecklistItem] {
        switch kind {
        case .parties:
            checklist.parties
        case .money:
            checklist.money
        case .dates:
            checklist.dates
        case .obligations:
            checklist.obligations
        case .questionsBeforeSigning:
            checklist.questionsBeforeSigning
        }
    }
}
