import Foundation
import Observation

@MainActor
@Observable
final class ItemDetailViewModel {
    var onEvent: (ItemDetailEvent) -> Void = { _ in }
    private(set) var state: ItemDetailState

    private let documentID: UUID
    private let itemID: UUID
    private let session: any DocumentSessionStoring
    private let purchases: any PurchasesServicing
    private let access = AccessPolicy()

    init(documentID: UUID, itemID: UUID, session: any DocumentSessionStoring, purchases: any PurchasesServicing) {
        self.documentID = documentID
        self.itemID = itemID
        self.session = session
        self.purchases = purchases
        state = .missing
        refreshAccess()
    }

    func refreshAccess() {
        state = resolved()
    }

    func unlock() {
        onEvent(.unlock)
    }

    private func resolved() -> ItemDetailState {
        guard case .checklist(let checklist) = session.reading(id: documentID)?.outcome,
              checklist.item(id: itemID) != nil else {
            return .missing
        }
        guard access.isOpen(itemID, in: checklist, hasPro: purchases.hasPro),
              let item = checklist.item(id: itemID) else {
            return .locked
        }
        return .loaded(item)
    }
}
