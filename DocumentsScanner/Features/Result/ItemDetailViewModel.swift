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
        guard let reading = session.reading(id: documentID),
              case .checklist(let checklist) = reading.outcome,
              let item = checklist.item(id: itemID) else {
            return .missing
        }
        guard access.isOpen(item.id, in: checklist, hasPro: purchases.hasPro) else {
            return .locked
        }
        let page = page(for: item, in: reading.document)
        return .loaded(
            ItemDetailContent(
                item: item,
                pageIndex: page?.index ?? item.pageIndex,
                pageText: page?.text ?? ""
            )
        )
    }

    private func page(for item: ChecklistItem, in document: RecognizedDocument) -> RecognizedPage? {
        let preferred = document.pages.filter { $0.index == item.pageIndex }
        let others = document.pages.filter { $0.index != item.pageIndex }.sorted { $0.index < $1.index }
        let ordered = preferred + others
        if let matched = ordered.first(where: { QuoteSpan.parts(of: item.quote, in: $0.text) != nil }) {
            return matched
        }
        return preferred.first ?? document.pages.min { $0.index < $1.index }
    }
}
