import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        DSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    Text(String(localized: "No lease yet"))
                        .font(DSFont.display)
                        .foregroundStyle(DSColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(String(localized: "Scan a paper lease or import a PDF. The checklist is built from the words on the page."))
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.inkSecondary)
                    DSButton(title: String(localized: "Scan a lease"), style: .primary) {
                        Task { await viewModel.scanTapped() }
                    }
                    DSButton(title: String(localized: "Import PDF or image"), style: .outlined) {
                        viewModel.importTapped()
                    }
                }
                .padding(DSSpacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(String(localized: "Lease Audit"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "History"), action: viewModel.historyTapped)
                    .font(DSFont.label)
                    .tint(DSColor.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Settings"), action: viewModel.settingsTapped)
                    .font(DSFont.label)
                    .tint(DSColor.ink)
            }
        }
        .alert(
            String(localized: "Camera access is off"),
            isPresented: $viewModel.showsCameraDenied
        ) {
            Button(String(localized: "Open Settings")) {
                viewModel.openSettings()
            }
            Button(String(localized: "Close"), role: .cancel) {}
        } message: {
            Text(String(localized: "Lease Audit needs the camera to scan a paper lease. You can turn it on in Settings."))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
