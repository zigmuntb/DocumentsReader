import Foundation

struct ItemDetailContent: Equatable, Sendable {
    let item: ChecklistItem
    let pageIndex: Int
    let pageText: String
}

enum ItemDetailState: Equatable {
    case missing
    case locked
    case loaded(ItemDetailContent)
}
