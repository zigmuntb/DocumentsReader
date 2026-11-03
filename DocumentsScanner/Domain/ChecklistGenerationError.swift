import Foundation

enum ChecklistGenerationError: Error, Equatable, Sendable {
    case refused
    case contextExceeded
    case undecodable
    case failed
}
