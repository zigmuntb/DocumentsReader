import Foundation

enum FallbackCopy {
    static func message(for reason: FallbackReason) -> String {
        switch reason {
        case .sparseText:
            String(localized: "Only a little text was found. A checklist needs more of the lease than this.")
        case .modelUnavailable:
            String(localized: "Apple Intelligence isn't available on this iPhone, so the lease text is below with a fixed list of questions.")
        case .modelNotReady:
            String(localized: "The on-device model isn't ready yet. The lease text is below, with a fixed list of questions.")
        case .modelRefused:
            String(localized: "The model declined to build a checklist. The lease text is below, with a fixed list of questions.")
        case .contextExceeded:
            String(localized: "The lease was too long for the on-device model. The text is below, with a fixed list of questions.")
        case .emptyModelAnswer:
            String(localized: "The model didn't return a fact tied to the text. The lease is below, with a fixed list of questions.")
        case .modelFailed:
            String(localized: "The checklist couldn't be built. The lease text is below, with a fixed list of questions.")
        }
    }
}
