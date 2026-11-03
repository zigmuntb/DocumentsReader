import Foundation

struct ChecklistPresentation: Equatable, Sendable {
    struct Section: Equatable, Sendable, Identifiable {
        let kind: ChecklistSectionKind
        let rows: [ChecklistRow]

        var id: ChecklistSectionKind { kind }
    }

    let sections: [Section]

    var hasLockedRows: Bool {
        sections.contains { section in
            section.rows.contains { row in
                if case .locked = row { return true }
                return false
            }
        }
    }
}
