import Foundation

@MainActor
final class ResultCoordinator {
    var onSelectItem: (_ documentID: UUID, _ itemID: UUID) -> Void = { _, _ in }

    func selectItem(documentID: UUID, itemID: UUID) {
        onSelectItem(documentID, itemID)
    }
}
