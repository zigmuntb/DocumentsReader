import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: SettingsViewModel

    var body: some View {
        DSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    status
                    if let notice = viewModel.notice {
                        Text(notice)
                            .font(DSFont.body)
                            .foregroundStyle(DSColor.primary)
                    }
                    if viewModel.isRestoring {
                        ProgressView()
                            .tint(DSColor.primary)
                            .accessibilityLabel(String(localized: "Restoring purchases"))
                    }
                    if !viewModel.hasPro {
                        DSButton(title: String(localized: "Unlock the rest"), style: .primary) {
                            viewModel.upgrade()
                        }
                        .disabled(viewModel.isRestoring)
                        .transition(.opacity)
                    }
                    DSButton(title: String(localized: "Restore purchases"), style: .outlined) {
                        Task { await viewModel.restore() }
                    }
                    .disabled(viewModel.isRestoring)
                    if let manage = SubscriptionLink.manage {
                        Link(String(localized: "Manage subscription"), destination: manage)
                            .font(DSFont.label)
                            .foregroundStyle(DSColor.secondary)
                            .frame(maxWidth: .infinity, minHeight: DSSpacing.touch, alignment: .leading)
                    }
                    legal
                }
                .padding(DSSpacing.l)
                .dsReplaces(viewModel.hasPro, reduceMotion: reduceMotion)
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
    }

    private var status: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(viewModel.hasPro ? String(localized: "Pro") : String(localized: "Free"))
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    viewModel.hasPro
                        ? String(localized: "Every checklist item is open.")
                        : String(localized: "The first two checklist items are free.")
                )
                .font(DSFont.body)
                .foregroundStyle(DSColor.inkSecondary)
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
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(purchases: PreviewSettingsPurchases()))
    }
}

@MainActor
private final class PreviewSettingsPurchases: PurchasesServicing {
    var hasPro = false
    func refresh() async {}
    func loadOfferings() async throws -> [LeaseOffering] { [] }
    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome { .cancelled }
    func restore() async throws {}
}
