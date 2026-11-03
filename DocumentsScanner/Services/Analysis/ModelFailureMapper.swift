import Foundation
import FoundationModels

enum ModelFailureMapper {
    /// Maps model failures without reading debug text, which can echo the lease.
    static func classify(_ error: Error) -> ChecklistGenerationError {
        if #available(iOS 27, *) {
            if let modern = error as? LanguageModelError {
                switch modern {
                case .contextSizeExceeded:
                    return .contextExceeded
                case .refusal:
                    return .refused
                default:
                    return .failed
                }
            }
        }
        guard let legacy = error as? LanguageModelSession.GenerationError else {
            return .failed
        }
        switch legacy {
        case .exceededContextWindowSize:
            return .contextExceeded
        case .refusal:
            return .refused
        case .decodingFailure:
            return .undecodable
        default:
            return .failed
        }
    }
}
