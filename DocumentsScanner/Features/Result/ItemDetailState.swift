import Foundation

enum ItemDetailState: Equatable {
    case missing
    case locked
    case loaded(ChecklistItem)
}
