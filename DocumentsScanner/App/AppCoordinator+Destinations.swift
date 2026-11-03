import SwiftUI

extension AppCoordinator {
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .processing(let documentID):
            if let model = processingModel(for: documentID) {
                ProcessingView(viewModel: model)
            }
        case .transcript(let documentID):
            if let model = transcriptModel(for: documentID) {
                TranscriptView(viewModel: model)
            }
        case .result(let documentID):
            if let model = resultModel(for: documentID) {
                ResultView(viewModel: model)
            }
        case .itemDetail(_, let itemID):
            if let model = detailModel(for: itemID) {
                ItemDetailView(viewModel: model)
            }
        case .history:
            HistoryView(viewModel: historyViewModel)
        case .settings:
            SettingsView(viewModel: settingsViewModel)
        }
    }

    @ViewBuilder
    func sheetContent(for sheet: SheetRoute) -> some View {
        NavigationStack {
            switch sheet {
            case .paywall:
                PaywallView(viewModel: paywallViewModel)
            case .disclaimer:
                DisclaimerView(viewModel: disclaimerViewModel)
                    .interactiveDismissDisabled()
            }
        }
        .dsNavigationChrome()
    }

    @ViewBuilder
    func coverContent(for cover: CoverRoute) -> some View {
        switch cover {
        case .scanner:
            ScanView(viewModel: scanViewModel)
        }
    }
}
