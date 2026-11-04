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
            case .loaded(let content):
                loaded(content)
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

    private func loaded(_ content: ItemDetailContent) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    Text(String(localized: "Not legal advice. Each item quotes the lease."))
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.inkSecondary)
                    DSCard {
                        ChecklistItemCard(item: content.item)
                    }
                    if !content.pageText.isEmpty {
                        passage(content, proxy: proxy)
                    }
                }
                .padding(DSSpacing.l)
            }
        }
    }

    private func passage(_ content: ItemDetailContent, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text(String(localized: "In the lease"))
                .font(DSFont.eyebrow)
                .tracking(DSFont.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundStyle(DSColor.secondary)
                .accessibilityAddTraits(.isHeader)
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.s) {
                    Text(String(localized: "Page \(content.pageIndex + 1)"))
                        .font(DSFont.eyebrow)
                        .tracking(DSFont.eyebrowTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(DSColor.secondary)
                    LeasePassageView(pageText: content.pageText, quote: content.item.quote) {
                        Task { @MainActor in
                            proxy.scrollTo(LeasePassageView.highlightID, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

private struct LeasePassageView: View {
    static let highlightID = "lease-quote"

    let pageText: String
    let quote: String
    var onHighlightAppear: () -> Void = {}

    var body: some View {
        let parts = QuoteSpan.parts(of: quote, in: pageText)
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            if let parts {
                if !parts.before.isEmpty {
                    passageText(parts.before)
                }
                DSQuoteBlock(text: parts.match)
                    .id(Self.highlightID)
                    .onAppear(perform: onHighlightAppear)
                if !parts.after.isEmpty {
                    passageText(parts.after)
                }
            } else {
                passageText(pageText)
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func passageText(_ text: String) -> some View {
        Text(text)
            .font(DSFont.body)
            .foregroundStyle(DSColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
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
            pages: [
                RecognizedPage(
                    index: 0,
                    text: "This lease is between Alice and Bob. \(item.quote) The term is one year."
                )
            ],
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
