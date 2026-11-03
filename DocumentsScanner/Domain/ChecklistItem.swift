import Foundation

struct ChecklistItem: Equatable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let plainExplanation: String
    let quote: String
    let pageIndex: Int
    let severity: ChecklistSeverity
}
