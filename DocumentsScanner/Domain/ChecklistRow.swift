import Foundation

/// A locked row carries an identifier only. The quote and explanation stay out of the view.
enum ChecklistRow: Equatable, Sendable, Identifiable {
    case open(ChecklistItem)
    case locked(UUID)

    var id: UUID {
        switch self {
        case .open(let item):
            item.id
        case .locked(let id):
            id
        }
    }
}
