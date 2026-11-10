import Foundation
import SwiftUI

struct ResultView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: ResultViewModel

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .missing:
                missing
                    .transition(.opacity)
            case .loaded(let checklist):
                loaded(checklist)
                    .transition(.opacity)
            }
        }
        .dsReplaces(viewModel.state, reduceMotion: reduceMotion)
        .navigationTitle(String(localized: "Checklist"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var missing: some View {
        Text(String(localized: "This reading is no longer on the device."))
            .font(DSFont.body)
            .foregroundStyle(DSColor.inkSecondary)
            .padding(DSSpacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func loaded(_ presentation: ChecklistPresentation) -> some View {
        let visible = viewModel.filtered ?? presentation
        VStack(spacing: 0) {
            if !presentation.sections.isEmpty {
                filters
            }
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    Text(String(localized: "Not legal advice. Each item quotes the lease."))
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.inkSecondary)
                    if presentation.hasLockedRows {
                        Text(String(localized: "The first two items are free. The rest unlock with Pro."))
                            .font(DSFont.body)
                            .foregroundStyle(DSColor.ink)
                    }
                    if visible.sections.isEmpty {
                        Text(String(localized: "Nothing matches those words."))
                            .font(DSFont.body)
                            .foregroundStyle(DSColor.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(visible.sections) { section in
                            sectionView(section)
                        }
                    }
                }
                .padding(DSSpacing.l)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.xs) {
                    filterChip(title: String(localized: "All"), isSelected: viewModel.selectedSection == nil) {
                        viewModel.selectedSection = nil
                    }
                    ForEach(viewModel.availableSections, id: \.self) { kind in
                        filterChip(title: kind.title, isSelected: viewModel.selectedSection == kind) {
                            viewModel.selectedSection = viewModel.selectedSection == kind ? nil : kind
                        }
                    }
                }
            }
            searchField
        }
        .padding(.horizontal, DSSpacing.l)
        .padding(.top, DSSpacing.m)
        .padding(.bottom, DSSpacing.s)
        .background(DSColor.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DSColor.hairline)
                .frame(height: 1)
        }
    }

    private var searchField: some View {
        HStack(spacing: DSSpacing.s) {
            TextField(String(localized: "Search found words"), text: query)
                .font(DSFont.body)
                .foregroundStyle(DSColor.ink)
                .tint(DSColor.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !viewModel.query.isEmpty {
                Button(String(localized: "Clear")) {
                    viewModel.query = ""
                }
                .font(DSFont.label)
                .foregroundStyle(DSColor.secondary)
            }
        }
        .padding(.horizontal, DSSpacing.m)
        .frame(minHeight: DSSpacing.touch)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous)
                .strokeBorder(DSColor.hairline, lineWidth: 1)
        }
    }

    private var query: Binding<String> {
        Binding(
            get: { viewModel.query },
            set: { viewModel.query = $0 }
        )
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DSFont.label)
                .foregroundStyle(isSelected ? DSColor.onInverted : DSColor.ink)
                .lineLimit(1)
                .padding(.horizontal, DSSpacing.m)
                .frame(minHeight: DSSpacing.touch)
                .background(
                    isSelected ? DSColor.inverted : DSColor.surface,
                    in: RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : DSColor.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func sectionView(_ section: ChecklistPresentation.Section) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text(section.kind.title)
                .font(DSFont.eyebrow)
                .tracking(DSFont.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundStyle(DSColor.secondary)
                .accessibilityAddTraits(.isHeader)
            ForEach(section.rows) { row in
                switch row {
                case .open(let item):
                    Button {
                        viewModel.select(item)
                    } label: {
                        DSCard {
                            ChecklistItemCard(item: item)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(String(localized: "Opens the full clause"))
                case .locked:
                    Button {
                        viewModel.unlock()
                    } label: {
                        DSCard {
                            LockedItemCard()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Unlock this item"))
                    .accessibilityHint(String(localized: "The quote stays hidden until you unlock Pro."))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

private extension ChecklistSectionKind {
    var title: String {
        switch self {
        case .parties:
            String(localized: "Parties")
        case .money:
            String(localized: "Money")
        case .dates:
            String(localized: "Dates")
        case .obligations:
            String(localized: "Obligations")
        case .questionsBeforeSigning:
            String(localized: "Before you sign")
        }
    }
}

#Preview {
    ResultPreview()
}

private struct ResultPreview: View {
    private let viewModel: ResultViewModel

    init() {
        let store = InMemoryDocumentSessionStore()
        let quote = "Tenant shall pay rent of $1,500 on the first day of each month."
        let document = RecognizedDocument(
            id: UUID(),
            pages: [RecognizedPage(index: 0, text: quote)],
            isSparse: false
        )
        let rent = ChecklistItem(
            id: UUID(),
            title: "Monthly rent",
            plainExplanation: "Rent is $1,500, due on the first.",
            quote: quote,
            pageIndex: 0,
            severity: .check
        )
        let deposit = ChecklistItem(
            id: UUID(),
            title: "Deposit",
            plainExplanation: "The deposit is one month of rent.",
            quote: quote,
            pageIndex: 0,
            severity: .ok
        )
        let late = ChecklistItem(
            id: UUID(),
            title: "Late fee",
            plainExplanation: "A late fee applies after the fifth.",
            quote: quote,
            pageIndex: 0,
            severity: .check
        )
        let checklist = LeaseChecklist(
            parties: [],
            money: [rent, deposit, late],
            dates: [],
            obligations: [],
            questionsBeforeSigning: []
        )
        store.save(LeaseReading(document: document, outcome: .checklist(checklist)))
        viewModel = ResultViewModel(
            documentID: document.id,
            session: store,
            purchases: PreviewPurchases(hasPro: false)
        )
    }

    var body: some View {
        NavigationStack {
            ResultView(viewModel: viewModel)
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
