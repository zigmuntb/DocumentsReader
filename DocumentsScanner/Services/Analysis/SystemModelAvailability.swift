import Foundation
import FoundationModels

struct SystemModelAvailability: ModelAvailabilityChecking {
    func readiness() -> ModelReadiness {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .modelNotReady:
                return .notReady
            case .deviceNotEligible, .appleIntelligenceNotEnabled:
                return .unavailable
            @unknown default:
                return .unavailable
            }
        }
    }
}
