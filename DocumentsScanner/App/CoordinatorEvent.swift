import Foundation

enum CoordinatorEvent: Equatable {
    case onboardingCompleted
    case scanTapped
    case importTapped
    case historyTapped
    case historyOpened(UUID)
    case settingsTapped
    case paywallRequested
    case paywallClosed
    case purchaseCompleted
    case showDisclaimer
    case disclaimerAcknowledged
    case scannerFinished(UUID)
    case scannerCancelled
    case scannerFailed
    case importReady(UUID)
    case importFailed
    case processingFinished(UUID)
    case processingCancelled
    case itemSelected(documentID: UUID, itemID: UUID)
}
