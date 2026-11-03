import Foundation
import SwiftUI

struct HistoryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: HistoryViewModel

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .empty:
                message(
                    String(localized: "No leases yet"),
                    detail: String(localized: "Finished readings stay on this device.")
                )
                .transition(.opacity)
            case .failed:
                message(
                    String(localized: "Saved leases couldn't be opened."),
                    detail: String(localized: "Finished readings stay on this device.")
                )
                .transition(.opacity)
            case .loaded(let entries):
                list(entries)
                    .transition(.opacity)
            }
        }
        .dsReplaces(viewModel.state, reduceMotion: reduceMotion)
        .navigationTitle(String(localized: "History"))
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.reload() }
    }

    private func list(_ entries: [LeaseHistoryEntry]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.s) {
                ForEach(entries) { entry in
                    Button {
                        viewModel.select(entry)
                    } label: {
                        DSCard {
                            row(entry)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(DSSpacing.l)
        }
    }

    private func row(_ entry: LeaseHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(entry.title ?? String(localized: "Lease"))
                .font(DSFont.title)
                .foregroundStyle(DSColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(DSFont.body)
                .foregroundStyle(DSColor.inkSecondary)
            Text(summary(entry.summary))
                .font(DSFont.eyebrow)
                .tracking(DSFont.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundStyle(DSColor.secondary)
        }
    }

    private func summary(_ summary: LeaseHistoryEntry.Summary) -> String {
        switch summary {
        case .checklist(let count) where count == 1:
            String(localized: "1 checklist item")
        case .checklist(let count):
            String(format: String(localized: "%lld checklist items"), Int64(count))
        case .textOnly:
            String(localized: "Recognized text")
        }
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text(title)
                .font(DSFont.display)
                .foregroundStyle(DSColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(DSFont.body)
                .foregroundStyle(DSColor.inkSecondary)
        }
        .padding(DSSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Empty") {
    NavigationStack {
        HistoryView(viewModel: HistoryViewModel(session: InMemoryDocumentSessionStore()))
    }
}

#Preview("Saved") {
    NavigationStack {
        HistoryView(viewModel: HistoryViewModel(session: SampleHistoryStore()))
    }
}

@MainActor
private final class SampleHistoryStore: DocumentSessionStoring {
    private let store = InMemoryDocumentSessionStore()

    init() {
        let document = RecognizedDocument(
            id: UUID(),
            pages: [RecognizedPage(index: 0, text: "Residential lease")],
            isSparse: false
        )
        store.save(
            LeaseReading(
                document: document,
                outcome: .checklist(
                    LeaseChecklist(
                        parties: [
                            ChecklistItem(
                                id: UUID(),
                                title: "Tenant",
                                plainExplanation: "Alice is the tenant.",
                                quote: "Residential lease",
                                pageIndex: 0,
                                severity: .ok
                            )
                        ],
                        money: [],
                        dates: [],
                        obligations: [],
                        questionsBeforeSigning: []
                    )
                )
            )
        )
    }

    func stage(_ job: RecognitionJob) -> UUID { store.stage(job) }
    func job(id: UUID) -> RecognitionJob? { store.job(id: id) }
    func save(_ document: RecognizedDocument) { store.save(document) }
    func document(id: UUID) -> RecognizedDocument? { store.document(id: id) }
    func save(_ reading: LeaseReading) { store.save(reading) }
    func reading(id: UUID) -> LeaseReading? { store.reading(id: id) }
    func history() throws -> [LeaseHistoryEntry] { try store.history() }
}
