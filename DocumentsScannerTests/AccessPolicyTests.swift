import Foundation
import Testing
@testable import DocumentsScanner

struct AccessPolicyTests {
    private let policy = AccessPolicy()

    @Test func theFirstTwoItemsStayOpen() {
        let items = sampleItems(count: 3)
        let presentation = policy.present(checklist(items), hasPro: false)
        let rows = presentation.sections.flatMap(\.rows)
        #expect(rows.count == 3)
        guard case .open(let first) = rows[0], case .open(let second) = rows[1], case .locked(let lockedID) = rows[2] else {
            Issue.record("Expected two open items and one locked id")
            return
        }
        #expect(first.id == items[0].id)
        #expect(second.quote == items[1].quote)
        #expect(lockedID == items[2].id)
        #expect(presentation.hasLockedRows)
    }

    @Test func proOpensEveryItem() {
        let items = sampleItems(count: 3)
        let presentation = policy.present(checklist(items), hasPro: true)
        let rows = presentation.sections.flatMap(\.rows)
        let quotes = rows.compactMap { row -> String? in
            if case .open(let item) = row { return item.quote }
            return nil
        }
        #expect(quotes == items.map(\.quote))
        #expect(presentation.hasLockedRows == false)
    }

    @Test func sectionsFollowTheChecklistOrder() {
        let party = item("Party", quote: "Alice is the tenant.")
        let rent = item("Rent", quote: "Rent is $1500.")
        let term = item("Term", quote: "The term is one year.")
        let checklist = LeaseChecklist(
            parties: [party],
            money: [rent],
            dates: [term],
            obligations: [],
            questionsBeforeSigning: []
        )
        let presentation = policy.present(checklist, hasPro: false)
        #expect(presentation.sections.map(\.kind) == [.parties, .money, .dates])
        guard case .locked = presentation.sections[2].rows[0] else {
            Issue.record("The third section should be locked")
            return
        }
        #expect(policy.isOpen(party.id, in: checklist, hasPro: false))
        #expect(policy.isOpen(term.id, in: checklist, hasPro: false) == false)
        #expect(policy.isOpen(term.id, in: checklist, hasPro: true))
    }

    @Test func fewerThanTwoItemsAreAllOpen() {
        let items = sampleItems(count: 1)
        let rows = policy.present(checklist(items), hasPro: false).sections.flatMap(\.rows)
        #expect(rows.count == 1)
        guard case .open = rows[0] else {
            Issue.record("A single item should be open")
            return
        }
    }

    private func checklist(_ items: [ChecklistItem]) -> LeaseChecklist {
        LeaseChecklist(
            parties: items,
            money: [],
            dates: [],
            obligations: [],
            questionsBeforeSigning: []
        )
    }

    private func sampleItems(count: Int) -> [ChecklistItem] {
        (0..<count).map { index in
            item("Item \(index)", quote: "Quote \(index) from the lease.")
        }
    }

    private func item(_ title: String, quote: String) -> ChecklistItem {
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
