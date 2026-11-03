import Foundation

enum ImportEvent: Equatable {
    case ready(UUID)
    case failed
}
