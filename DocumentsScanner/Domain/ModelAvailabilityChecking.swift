import Foundation

protocol ModelAvailabilityChecking: Sendable {
    func readiness() -> ModelReadiness
}
