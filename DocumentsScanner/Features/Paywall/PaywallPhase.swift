import Foundation

enum PaywallPhase: Equatable {
    case loading
    case ready
    case failed(PurchaseFailure)
}
