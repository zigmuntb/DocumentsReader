import Foundation

enum DocumentReadError: LocalizedError, Equatable {
    case unreadableFile
    case noPages
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            String(localized: "This file couldn't be opened.")
        case .noPages:
            String(localized: "This file has no pages.")
        case .recognitionFailed:
            String(localized: "Text recognition failed.")
        }
    }
}
