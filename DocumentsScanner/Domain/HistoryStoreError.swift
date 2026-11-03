import Foundation

enum HistoryStoreError: Error, Equatable, LocalizedError {
    case unreadable

    var errorDescription: String? {
        String(localized: "Saved leases couldn't be opened.")
    }
}
