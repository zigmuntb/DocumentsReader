import Foundation

/// Narrows a checklist to one section and to the words the reading already found.
struct ChecklistFilter: Sendable {
    func apply(
        _ presentation: ChecklistPresentation,
        source: LeaseChecklist,
        query: String,
        section: ChecklistSectionKind?
    ) -> ChecklistPresentation {
        let needles = QuoteSpan.terms(in: query)
        let sections = presentation.sections.compactMap { group -> ChecklistPresentation.Section? in
            if let section, group.kind != section {
                return nil
            }
            let rows = group.rows.filter { matches($0, needles: needles, source: source) }
            guard !rows.isEmpty else { return nil }
            return ChecklistPresentation.Section(kind: group.kind, rows: rows)
        }
        return ChecklistPresentation(sections: sections)
    }

    private func matches(_ row: ChecklistRow, needles: [String], source: LeaseChecklist) -> Bool {
        guard !needles.isEmpty else { return true }
        guard let item = source.item(id: row.id) else { return false }
        let terms = Set(QuoteSpan.terms(in: "\(item.title)\n\(item.plainExplanation)\n\(item.quote)"))
        return needles.allSatisfy { needle in
            terms.contains { term in
                term == needle || (needle.count >= 2 && term.hasPrefix(needle))
            }
        }
    }
}
