import Foundation

enum CaptureNotice: Equatable, Identifiable {
    case importFailed
    case scanFailed

    var id: Self { self }

    var title: String {
        switch self {
        case .importFailed:
            String(localized: "Couldn't open that file")
        case .scanFailed:
            String(localized: "The scan didn't come through")
        }
    }

    var message: String {
        switch self {
        case .importFailed:
            String(localized: "Choose a PDF or an image. The file stays on this device.")
        case .scanFailed:
            String(localized: "The camera didn't return any pages. Try the scan again.")
        }
    }
}
