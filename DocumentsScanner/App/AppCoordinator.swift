import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
    let container: DependencyContainer

    private(set) var root: AppRoot
    var path: [Route] = []
    var sheet: SheetRoute?
    var cover: CoverRoute?
    var isImporterPresented = false
    var notice: CaptureNotice?

    let onboardingCoordinator = OnboardingCoordinator()
    let scanCoordinator = ScanCoordinator()
    let resultCoordinator = ResultCoordinator()
    let paywallCoordinator = PaywallCoordinator()

    let onboardingViewModel = OnboardingViewModel()
    let homeViewModel: HomeViewModel
    let scanViewModel: ScanViewModel
    let importViewModel: ImportViewModel
    let paywallViewModel: PaywallViewModel
    let disclaimerViewModel = DisclaimerViewModel()
    let historyViewModel: HistoryViewModel
    let settingsViewModel: SettingsViewModel

    private var pendingDocumentID: UUID?
    var processingViewModels: [UUID: ProcessingViewModel] = [:]
    var transcriptViewModels: [UUID: TranscriptViewModel] = [:]
    var resultViewModels: [UUID: ResultViewModel] = [:]
    var detailViewModels: [UUID: ItemDetailViewModel] = [:]

    init(container: DependencyContainer) {
        self.container = container
        root = container.onboardingStore.isComplete ? .home : .onboarding
        homeViewModel = HomeViewModel(
            camera: container.cameraAuthorizer,
            settings: container.settingsOpener
        )
        scanViewModel = ScanViewModel(session: container.sessionStore)
        importViewModel = ImportViewModel(session: container.sessionStore)
        paywallViewModel = PaywallViewModel(purchases: container.purchases)
        historyViewModel = HistoryViewModel(session: container.sessionStore)
        settingsViewModel = SettingsViewModel(purchases: container.purchases)
        bindChildren()
    }

    func processingModel(for documentID: UUID) -> ProcessingViewModel? {
        processingViewModels[documentID]
    }

    func transcriptModel(for documentID: UUID) -> TranscriptViewModel? {
        transcriptViewModels[documentID]
    }

    func resultModel(for documentID: UUID) -> ResultViewModel? {
        resultViewModels[documentID]
    }

    func detailModel(for itemID: UUID) -> ItemDetailViewModel? {
        detailViewModels[itemID]
    }

    func handle(_ event: CoordinatorEvent) {
        switch event {
        case .onboardingCompleted:
            container.onboardingStore.markComplete()
            root = .home
        case .scanTapped:
            cover = .scanner
        case .importTapped:
            isImporterPresented = true
        case .historyTapped:
            historyViewModel.reload()
            push(.history)
        case .historyOpened(let documentID):
            presentReading(documentID)
        case .settingsTapped:
            push(.settings)
        case .paywallRequested:
            sheet = .paywall
        case .paywallClosed:
            dismiss(.paywall)
        case .purchaseCompleted:
            refreshOpenReadings()
            settingsViewModel.applyCurrentAccess()
            dismiss(.paywall)
        case .showDisclaimer:
            sheet = .disclaimer
        case .disclaimerAcknowledged:
            container.disclaimerStore.acknowledge()
            let documentID = pendingDocumentID
            pendingDocumentID = nil
            dismiss(.disclaimer)
            if let documentID {
                openReading(documentID)
            }
        case .scannerFinished(let documentID):
            cover = nil
            startProcessing(documentID)
        case .scannerCancelled:
            cover = nil
        case .scannerFailed:
            cover = nil
            notice = .scanFailed
        case .importReady(let documentID):
            isImporterPresented = false
            startProcessing(documentID)
        case .importFailed:
            isImporterPresented = false
            notice = .importFailed
        case .processingFinished(let documentID):
            if case .processing = path.last {
                path.removeLast()
            }
            presentReading(documentID)
        case .processingCancelled:
            if case .processing = path.last {
                path.removeLast()
            }
        case .itemSelected(let documentID, let itemID):
            openItem(documentID: documentID, itemID: itemID)
        }
    }

    private func startProcessing(_ documentID: UUID) {
        if processingViewModels[documentID] == nil {
            let model = ProcessingViewModel(
                documentID: documentID,
                session: container.sessionStore,
                recognizer: container.textRecognizer,
                analyzer: container.leaseAnalyzer
            )
            model.onEvent = { [weak self] event in
                if case .finished(let id) = event {
                    self?.handle(.processingFinished(id))
                }
            }
            processingViewModels[documentID] = model
        }
        push(.processing(documentID: documentID))
    }

    private func presentReading(_ documentID: UUID) {
        if container.disclaimerStore.isAcknowledged {
            openReading(documentID)
        } else {
            pendingDocumentID = documentID
            sheet = .disclaimer
        }
    }

    private func refreshOpenReadings() {
        for model in resultViewModels.values {
            model.refreshAccess()
        }
        for model in detailViewModels.values {
            model.refreshAccess()
        }
    }

    func push(_ route: Route) {
        guard !path.contains(route) else { return }
        path.append(route)
    }

    private func dismiss(_ route: SheetRoute) {
        if sheet == route {
            sheet = nil
        }
    }

}
