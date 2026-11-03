import Foundation
import SwiftUI

struct ItemDetailView: View {
    let viewModel: ItemDetailViewModel

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .missing:
                Text(String(localized: "The clause is no longer on the device."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                    .padding(DSSpacing.l)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .locked:
                locked
            case .loaded(let item):
                loaded(item)
            }
        }
        .navigationTitle(String(localized: "Clause"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var locked: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                Text(String(localized: "This item is part of Pro."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.ink)
                Text(String(localized: "The first two items are free. The rest unlock with Pro."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                DSButton(title: String(localized: "Unlock"), style: .primary) {
                    viewModel.unlock()
                }
            }
            .padding(DSSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loaded(_ item: ChecklistItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                Text(String(localized: "Not legal advice. Each item quotes the lease."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                DSCard {
                    ChecklistItemCard(item: item)
                }
                Text(String(localized: "Page \(item.pageIndex + 1)"))
                    .font(DSFont.eyebrow)
                    .tracking(DSFont.eyebrowTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(DSColor.secondary)
            }
            .padding(DSSpacing.l)
        }
    }
}

#Preview {
    ItemDetailPreview()
}

private struct ItemDetailPreview: View {
    private let viewModel: ItemDetailViewModel

    init() {
        let store = InMemoryDocumentSessionStore()
        let item = ChecklistItem(
            id: UUID(),
            title: "Monthly rent",
            plainExplanation: "Rent is $1,500, due on the first.",
            quote: "Tenant shall pay rent of $1,500 on the first day of each month.",
            pageIndex: 0,
            severity: .check
        )
        let document = RecognizedDocument(
            id: UUID(),
            pages: [RecognizedPage(index: 0, text: item.quote)],
            isSparse: false
        )
        store.save(
            LeaseReading(
                document: document,
                outcome: .checklist(
                    LeaseChecklist(
                        parties: [],
                        money: [item],
                        dates: [],
                        obligations: [],
                        questionsBeforeSigning: []
                    )
                )
            )
        )
        viewModel = ItemDetailViewModel(
            documentID: document.id,
            itemID: item.id,
            session: store,
            purchases: PreviewPurchases(hasPro: true)
        )
    }

    var body: some View {
        NavigationStack {
            ItemDetailView(viewModel: viewModel)
        }
    }
}

@MainActor
private final class PreviewPurchases: PurchasesServicing {
    var hasPro: Bool

    init(hasPro: Bool) {
        self.hasPro = hasPro
    }

    func refresh() async {}

    func loadOfferings() async throws -> [LeaseOffering] { [] }

    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome { .cancelled }

    func restore() async throws {}
}
