import Foundation
import Observation

@MainActor
@Observable
final class ResultViewModel {
    var onEvent: (ResultEvent) -> Void = { _ in }
    private(set) var state: ResultState
    var query = ""
    var selectedSection: ChecklistSectionKind?

    private let checklist: LeaseChecklist?
    private let purchases: any PurchasesServicing
    private let access = AccessPolicy()
    private let checklistFilter = ChecklistFilter()

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

    var availableSections: [ChecklistSectionKind] {
        guard case .loaded(let presentation) = state else { return [] }
        return presentation.sections.map(\.kind)
    }

    var filtered: ChecklistPresentation? {
        guard case .loaded(let presentation) = state, let checklist else { return nil }
        return checklistFilter.apply(
            presentation,
            source: checklist,
            query: query,
            section: selectedSection
        )
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
