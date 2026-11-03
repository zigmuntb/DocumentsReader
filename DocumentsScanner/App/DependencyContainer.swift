import Foundation

/// Composition root. Views never build services themselves.
/// Storage choice: files in Application Support, because a lease is page images plus JSON and SwiftData fights those blobs.
/// A finished reading is written under Application Support. A scan that is still running stays in memory.
@MainActor
final class DependencyContainer {
    let onboardingStore: any OnboardingStoring
    let sessionStore: any DocumentSessionStoring
    let textRecognizer: any TextRecognizing
    let leaseAnalyzer: any LeaseAnalyzing
    let purchases: any PurchasesServicing
    let disclaimerStore: any DisclaimerStoring
    let cameraAuthorizer: any CameraAuthorizing
    let settingsOpener: any SettingsOpening

    init(
        onboardingStore: any OnboardingStoring = UserDefaultsOnboardingStore(),
        sessionStore: any DocumentSessionStoring = FileLeaseArchive.live(),
        textRecognizer: any TextRecognizing = LeaseTextRecognizer(),
        leaseAnalyzer: (any LeaseAnalyzing)? = nil,
        purchases: (any PurchasesServicing)? = nil,
        disclaimerStore: any DisclaimerStoring = UserDefaultsDisclaimerStore(),
        cameraAuthorizer: any CameraAuthorizing = SystemCameraAuthorizer(),
        settingsOpener: (any SettingsOpening)? = nil
    ) {
        self.onboardingStore = onboardingStore
        self.sessionStore = sessionStore
        self.textRecognizer = textRecognizer
        self.leaseAnalyzer = leaseAnalyzer ?? LeaseChecklistAnalyzer(
            availability: SystemModelAvailability(),
            generator: FoundationModelChecklistGenerator()
        )
        self.purchases = purchases ?? StoreKitPurchaseService()
        self.disclaimerStore = disclaimerStore
        self.cameraAuthorizer = cameraAuthorizer
        self.settingsOpener = settingsOpener ?? SystemSettingsOpener()
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(container: self)
    }
}
