import Foundation
import SwiftUI

struct PaywallView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: PaywallViewModel

    var body: some View {
        DSScreen {
            switch viewModel.phase {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .tint(DSColor.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(String(localized: "Loading plans"))
                    .transition(.opacity)
            case .failed(let failure):
                failureView(failure)
                    .transition(.opacity)
            case .ready:
                ready
                    .transition(.opacity)
            }
        }
        .dsReplaces(viewModel.phase, reduceMotion: reduceMotion)
        .navigationTitle(String(localized: "Lease Audit Pro"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Close")) {
                    viewModel.close()
                }
                .disabled(viewModel.isPurchasing)
            }
        }
        .interactiveDismissDisabled(viewModel.isPurchasing)
        .task { await viewModel.load() }
    }

    private var ready: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                Text(String(localized: "The first two items are free. Pro opens every quote in the checklist. Your lease stays on this device."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.ink)
                if viewModel.isPurchasing {
                    ProgressView()
                        .tint(DSColor.primary)
                        .accessibilityLabel(String(localized: "Purchasing"))
                }
                if let notice = viewModel.notice {
                    Text(notice)
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.primary)
                }
                ForEach(viewModel.offerings) { offering in
                    offeringCard(offering)
                }
                Text(String(localized: "No weekly plan. No free trial."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                rights
                DSButton(title: String(localized: "Restore purchases"), style: .outlined) {
                    Task { await viewModel.restore() }
                }
                .disabled(viewModel.isPurchasing)
                legal
                Text(String(localized: "Cancel the yearly plan in the App Store."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
            }
            .padding(DSSpacing.l)
        }
    }

    private var rights: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.s) {
                Text(String(localized: "What you are buying"))
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.ink)
                    .accessibilityAddTraits(.isHeader)
                right(String(localized: "Your lease text stays on this device."))
                right(String(localized: "The first two checklist items are free."))
                right(String(localized: "A year at a time, or one lifetime purchase."))
            }
        }
    }

    private func right(_ text: String) -> some View {
        Text(text)
            .font(DSFont.body)
            .foregroundStyle(DSColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func offeringCard(_ offering: LeaseOffering) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.s) {
                Text(offering.kind == .yearly ? String(localized: "Yearly") : String(localized: "Lifetime"))
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.ink)
                Text(offering.displayPrice)
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.ink)
                Text(offering.kind == .yearly ? String(localized: "per year") : String(localized: "once"))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                DSButton(
                    title: offering.kind == .yearly
                        ? String(localized: "Subscribe yearly")
                        : String(localized: "Buy lifetime"),
                    style: .primary
                ) {
                    Task { await viewModel.buy(offering.kind) }
                }
                .disabled(viewModel.isPurchasing)
            }
        }
    }

    private var legal: some View {
        HStack(spacing: DSSpacing.m) {
            if let terms = LegalLink.terms {
                Link(String(localized: "Terms"), destination: terms)
            }
            if let privacy = LegalLink.privacy {
                Link(String(localized: "Privacy"), destination: privacy)
            }
        }
        .font(DSFont.label)
        .foregroundStyle(DSColor.secondary)
        .frame(minHeight: DSSpacing.touch)
    }

    private func failureView(_ failure: PurchaseFailure) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                Text(failure.errorDescription ?? String(localized: "The plans couldn't be loaded. Check the connection and try again."))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.ink)
                DSButton(title: String(localized: "Try again"), style: .primary) {
                    Task { await viewModel.load() }
                }
            }
            .padding(DSSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView(viewModel: PaywallViewModel(purchases: PreviewPurchases()))
    }
}

@MainActor
private final class PreviewPurchases: PurchasesServicing {
    var hasPro = false

    func refresh() async {}

    func loadOfferings() async throws -> [LeaseOffering] {
        [
            LeaseOffering(kind: .yearly, displayPrice: "$29.99"),
            LeaseOffering(kind: .lifetime, displayPrice: "$49.99")
        ]
    }

    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome { .cancelled }

    func restore() async throws {}
}
