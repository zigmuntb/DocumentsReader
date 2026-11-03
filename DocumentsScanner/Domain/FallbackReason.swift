import Foundation

/// Why the checklist was not shown. The recognized text is still the screen.
enum FallbackReason: Equatable, Sendable {
    case sparseText
    case modelUnavailable
    case modelNotReady
    case modelRefused
    case contextExceeded
    case emptyModelAnswer
    case modelFailed
}
