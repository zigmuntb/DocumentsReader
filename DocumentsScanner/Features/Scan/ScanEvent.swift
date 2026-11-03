import Foundation

enum ScanEvent: Equatable {
    case finished(UUID)
    case cancelled
    case failed
}
