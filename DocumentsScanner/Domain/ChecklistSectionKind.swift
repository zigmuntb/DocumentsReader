import Foundation

enum ChecklistSectionKind: Equatable, Hashable, Sendable, CaseIterable {
    case parties
    case money
    case dates
    case obligations
    case questionsBeforeSigning
}
