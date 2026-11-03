import Foundation

/// Pushed screens. Modals stay in `SheetRoute` and `CoverRoute` so they are not stacked under a back button.
enum Route: Hashable {
    case processing(documentID: UUID)
    case transcript(documentID: UUID)
    case result(documentID: UUID)
    case itemDetail(documentID: UUID, itemID: UUID)
    case history
    case settings
}
