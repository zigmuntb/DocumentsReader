import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct ResultViewModelTests {
    @Test func selectingAnItemEmitsItsIdentifier() {
        let item = sampleItem(title: "Monthly rent", quote: "Tenant shall pay rent of $1,500.")
        let (model, _, _) = model(items: [item])
        var selected: UUID?
        model.onEvent = { event in
            if case .openItem(let id) = event {
                selected = id
            }
        }
        model.select(item)
        #expect(selected == item.id)
    }

    @Test func aMissingReadingStaysMissing() {
        let store = InMemoryDocumentSessionStore()
        let model = ResultViewModel(documentID: UUID(), session: store, purchases: ScriptedPurchases())
        #expect(model.state == .missing)
    }

    @Test func detailLoadsTheSelectedClause() {
        let item = sampleItem(title: "Monthly rent", quote: "Tenant shall pay rent of $1,500.")
        let (_, store, documentID) = model(items: [item])
        let detail = ItemDetailViewModel(
            documentID: documentID,
            itemID: item.id,
            session: store,
            purchases: ScriptedPurchases()
        )
        #expect(detail.state == .loaded(item))
    }

    @Test func aThirdItemStaysLockedUntilPro() {
        let items = [
            sampleItem(title: "One", quote: "Quote one from the lease."),
            sampleItem(title: "Two", quote: "Quote two from the lease."),
            sampleItem(title: "Three", quote: "Quote three from the lease.")
        ]
        let purchases = ScriptedPurchases()
        let (model, store, documentID) = model(items: items, purchases: purchases)
        guard case .loaded(let presentation) = model.state else {
            Issue.record("Expected a checklist")
            return
        }
        let rows = presentation.sections.flatMap(\.rows)
        #expect(rows.count == 3)
        guard case .locked = rows[2] else {
            Issue.record("The third item should be locked")
            return
        }
        var events: [ResultEvent] = []
        model.onEvent = { events.append($0) }
        model.unlock()
        #expect(events == [.unlock])

        let detail = ItemDetailViewModel(
            documentID: documentID,
            itemID: items[2].id,
            session: store,
            purchases: purchases
        )
        #expect(detail.state == .locked)

        purchases.hasPro = true
        model.refreshAccess()
        detail.refreshAccess()
        guard case .loaded(let unlocked) = model.state else {
            Issue.record("Expected the checklist to open")
            return
        }
        let openQuotes = unlocked.sections.flatMap(\.rows).compactMap { row -> String? in
            if case .open(let item) = row { return item.quote }
            return nil
        }
        #expect(openQuotes == items.map(\.quote))
        #expect(detail.state == .loaded(items[2]))
    }

    private func model(
        items: [ChecklistItem],
        purchases: ScriptedPurchases = ScriptedPurchases()
    ) -> (ResultViewModel, InMemoryDocumentSessionStore, UUID) {
        let store = InMemoryDocumentSessionStore()
        let document = RecognizedDocument(
            id: UUID(),
            pages: [RecognizedPage(index: 0, text: items.map(\.quote).joined(separator: " "))],
            isSparse: false
        )
        store.save(
            LeaseReading(
                document: document,
                outcome: .checklist(
                    LeaseChecklist(
                        parties: items,
                        money: [],
                        dates: [],
                        obligations: [],
                        questionsBeforeSigning: []
                    )
                )
            )
        )
        return (
            ResultViewModel(documentID: document.id, session: store, purchases: purchases),
            store,
            document.id
        )
    }

    private func sampleItem(title: String, quote: String) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            title: title,
            plainExplanation: "Plain words.",
            quote: quote,
            pageIndex: 0,
            severity: .check
        )
    }
}
