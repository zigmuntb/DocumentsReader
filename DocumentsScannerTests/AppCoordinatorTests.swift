import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct AppCoordinatorTests {
    @Test func incompleteStoreStartsOnOnboarding() {
        let coordinator = makeCoordinator(complete: false)
        #expect(coordinator.root == .onboarding)
        #expect(coordinator.path.isEmpty)
    }

    @Test func completeStoreStartsAtHome() {
        let coordinator = makeCoordinator(complete: true)
        #expect(coordinator.root == .home)
    }

    @Test func continuingOnboardingPersistsAndShowsHome() {
        let store = InMemoryOnboardingStore()
        let coordinator = AppCoordinator(container: DependencyContainer(onboardingStore: store))
        coordinator.onboardingViewModel.continueTapped()
        #expect(coordinator.root == .home)
        #expect(store.isComplete)
    }

    @Test func scanPresentsCameraAndCloseDismissesIt() async {
        let coordinator = makeCoordinator(complete: true)
        await coordinator.homeViewModel.scanTapped()
        #expect(coordinator.cover == .scanner)
        coordinator.scanCoordinator.cancel()
        #expect(coordinator.cover == nil)
    }

    @Test func finishedScanOpensProcessing() {
        let coordinator = makeCoordinator(complete: true)
        let documentID = UUID()
        coordinator.handle(.scanTapped)
        coordinator.scanCoordinator.finish(documentID: documentID)
        #expect(coordinator.cover == nil)
        #expect(coordinator.path == [.processing(documentID: documentID)])
    }

    @Test func importPresentsTheFilePicker() {
        let coordinator = makeCoordinator(complete: true)
        coordinator.homeViewModel.importTapped()
        #expect(coordinator.isImporterPresented)
    }

    @Test func readyImportStartsProcessing() {
        let coordinator = makeCoordinator(complete: true)
        let documentID = UUID()
        coordinator.handle(.importReady(documentID))
        #expect(coordinator.isImporterPresented == false)
        #expect(coordinator.path == [.processing(documentID: documentID)])
    }

    @Test func historyAndSettingsPushOnce() {
        let coordinator = makeCoordinator(complete: true)
        coordinator.homeViewModel.historyTapped()
        coordinator.homeViewModel.historyTapped()
        coordinator.homeViewModel.settingsTapped()
        #expect(coordinator.path == [.history, .settings])
    }

    @Test func paywallCloseGoesThroughPaywallCoordinator() {
        let coordinator = makeCoordinator(complete: true)
        coordinator.handle(.paywallRequested)
        #expect(coordinator.sheet == .paywall)
        coordinator.paywallViewModel.close()
        #expect(coordinator.sheet == nil)
    }

    @Test func acknowledgingDisclaimerDismissesIt() {
        let coordinator = makeCoordinator(complete: true)
        coordinator.handle(.showDisclaimer)
        coordinator.disclaimerViewModel.acknowledge()
        #expect(coordinator.sheet == nil)
    }

    @Test func processingFinishReplacesTheSpinnerWithTheTranscript() {
        let coordinator = makeCoordinator(complete: true)
        let documentID = UUID()
        coordinator.path = [.processing(documentID: documentID)]
        coordinator.handle(.processingCancelled)
        #expect(coordinator.path.isEmpty)

        coordinator.handle(.processingFinished(documentID))
        #expect(coordinator.path == [.transcript(documentID: documentID)])
        coordinator.handle(.processingCancelled)
        #expect(coordinator.path == [.transcript(documentID: documentID)])
    }

    @Test func checklistReplacesTheSpinnerWithTheResult() {
        let store = InMemoryDocumentSessionStore()
        let coordinator = AppCoordinator(
            container: DependencyContainer(
                onboardingStore: InMemoryOnboardingStore(isComplete: true),
                sessionStore: store,
                purchases: ScriptedPurchases(),
                disclaimerStore: InMemoryDisclaimerStore(isAcknowledged: true),
                cameraAuthorizer: AuthorizedCamera()
            )
        )
        let documentID = UUID()
        let quote = "Tenant shall pay rent of $1500."
        let document = RecognizedDocument(
            id: documentID,
            pages: [RecognizedPage(index: 0, text: quote)],
            isSparse: false
        )
        store.save(
            LeaseReading(
                document: document,
                outcome: .checklist(
                    LeaseChecklist(
                        parties: [],
                        money: [
                            ChecklistItem(
                                id: UUID(),
                                title: "Rent",
                                plainExplanation: "Rent is $1500.",
                                quote: quote,
                                pageIndex: 0,
                                severity: .check
                            )
                        ],
                        dates: [],
                        obligations: [],
                        questionsBeforeSigning: []
                    )
                )
            )
        )
        coordinator.path = [.processing(documentID: documentID)]
        coordinator.handle(.processingFinished(documentID))
        #expect(coordinator.path == [.result(documentID: documentID)])
    }

    @Test func selectingAnItemPushesDetail() {
        let coordinator = makeCoordinator(complete: true)
        let documentID = UUID()
        let itemID = UUID()
        coordinator.resultCoordinator.selectItem(documentID: documentID, itemID: itemID)
        #expect(coordinator.path == [.itemDetail(documentID: documentID, itemID: itemID)])
    }

    @Test func theFirstReadingWaitsForTheDisclaimer() {
        let disclaimer = InMemoryDisclaimerStore()
        let coordinator = makeCoordinator(complete: true, disclaimer: disclaimer)
        let documentID = UUID()
        coordinator.path = [.processing(documentID: documentID)]
        coordinator.handle(.processingFinished(documentID))
        #expect(coordinator.sheet == .disclaimer)
        #expect(coordinator.path.isEmpty)

        coordinator.disclaimerViewModel.acknowledge()
        #expect(disclaimer.isAcknowledged)
        #expect(coordinator.sheet == nil)
        #expect(coordinator.path == [.transcript(documentID: documentID)])

        let nextID = UUID()
        coordinator.handle(.processingFinished(nextID))
        #expect(coordinator.sheet == nil)
        #expect(coordinator.path.contains(.transcript(documentID: nextID)))
    }

    @Test func aPurchaseClosesThePaywall() async {
        let purchases = ScriptedPurchases()
        let coordinator = makeCoordinator(complete: true, purchases: purchases)
        coordinator.handle(.paywallRequested)
        await coordinator.paywallViewModel.buy(.yearly)
        #expect(coordinator.sheet == nil)
        #expect(purchases.hasPro)
        #expect(coordinator.settingsViewModel.hasPro)
    }

    @Test func aSavedLeaseOpensFromHistory() {
        let store = InMemoryDocumentSessionStore()
        let documentID = UUID()
        store.save(sampleReading(id: documentID))
        let coordinator = makeCoordinator(complete: true, session: store)
        coordinator.homeViewModel.historyTapped()
        #expect(coordinator.path == [.history])
        guard case .loaded(let entries) = coordinator.historyViewModel.state else {
            Issue.record("History should list the saved lease")
            return
        }
        coordinator.historyViewModel.select(entries[0])
        #expect(coordinator.path == [.history, .result(documentID: documentID)])
    }

    @Test func settingsUpgradeOpensThePaywall() {
        let coordinator = makeCoordinator(complete: true)
        coordinator.homeViewModel.settingsTapped()
        coordinator.settingsViewModel.upgrade()
        #expect(coordinator.path == [.settings])
        #expect(coordinator.sheet == .paywall)
    }

    private func sampleReading(id: UUID) -> LeaseReading {
        LeaseReading(
            document: RecognizedDocument(
                id: id,
                pages: [RecognizedPage(index: 0, text: "Residential lease")],
                isSparse: false
            ),
            outcome: .checklist(
                LeaseChecklist(
                    parties: [
                        ChecklistItem(
                            id: UUID(),
                            title: "Tenant",
                            plainExplanation: "The tenant is named.",
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
    }

    private func makeCoordinator(
        complete: Bool,
        session: (any DocumentSessionStoring)? = nil,
        disclaimer: InMemoryDisclaimerStore? = nil,
        purchases: ScriptedPurchases = ScriptedPurchases()
    ) -> AppCoordinator {
        AppCoordinator(
            container: DependencyContainer(
                onboardingStore: InMemoryOnboardingStore(isComplete: complete),
                sessionStore: session ?? InMemoryDocumentSessionStore(),
                purchases: purchases,
                disclaimerStore: disclaimer ?? InMemoryDisclaimerStore(isAcknowledged: true),
                cameraAuthorizer: AuthorizedCamera()
            )
        )
    }
}

private struct AuthorizedCamera: CameraAuthorizing {
    func resolveAccess() async -> CameraAccess {
        .authorized
    }
}
