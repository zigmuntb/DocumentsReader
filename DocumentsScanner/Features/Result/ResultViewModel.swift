import Foundation
import Observation

@MainActor
@Observable
final class ResultViewModel {
    var onEvent: (ResultEvent) -> Void = { _ in }
    private(set) var state: ResultState

    private let checklist: LeaseChecklist?
    private let purchases: any PurchasesServicing
    private let access = AccessPolicy()

    init(documentID: UUID, session: any DocumentSessionStoring, purchases: any PurchasesServicing) {
        self.purchases = purchases
        if case .checklist(let checklist) = session.reading(id: documentID)?.outcome {
            self.checklist = checklist
            state = .loaded(access.present(checklist, hasPro: purchases.hasPro))
        } else {
            self.checklist = nil
            state = .missing
        }
    }

    func refreshAccess() {
        guard let checklist else { return }
        state = .loaded(access.present(checklist, hasPro: purchases.hasPro))
    }

    func select(_ item: ChecklistItem) {
        onEvent(.openItem(item.id))
    }

    func unlock() {
        onEvent(.unlock)
    }
}
