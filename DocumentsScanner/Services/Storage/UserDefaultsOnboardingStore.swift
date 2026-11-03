import Foundation

@MainActor
final class UserDefaultsOnboardingStore: OnboardingStoring {
    private let defaults: UserDefaults
    private let key = "leaseaudit.onboarding.completed"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isComplete: Bool {
        defaults.bool(forKey: key)
    }

    func markComplete() {
        defaults.set(true, forKey: key)
    }
}
