import Foundation

enum ProcessingFailure: Equatable {
    case noText
    case unreadable
    case failed

    var message: String {
        switch self {
        case .noText:
            String(localized: "No text was found. Try a clearer photo or a PDF with a text layer.")
        case .unreadable:
            String(localized: "This file couldn't be opened.")
        case .failed:
            String(localized: "Text recognition failed. Nothing was uploaded.")
        }
    }
}
