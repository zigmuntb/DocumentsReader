import Foundation

enum PurchaseFailure: Error, Equatable, Sendable, LocalizedError {
    case productsUnavailable
    case unverified
    case failed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .productsUnavailable:
            String(localized: "The plans couldn't be loaded. Check the connection and try again.")
        case .unverified:
            String(localized: "The purchase couldn't be verified.")
        case .failed:
            String(localized: "The purchase didn't go through.")
        case .cancelled:
            nil
        }
    }
}
