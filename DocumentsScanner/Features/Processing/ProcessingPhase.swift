import Foundation

enum ProcessingPhase: Equatable {
    case idle
    case reading(completed: Int, total: Int)
    case checking(completed: Int, total: Int)
    case failed(ProcessingFailure)
}
