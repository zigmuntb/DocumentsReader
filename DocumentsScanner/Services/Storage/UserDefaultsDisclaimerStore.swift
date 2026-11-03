import Foundation

@MainActor
final class UserDefaultsDisclaimerStore: DisclaimerStoring {
    private let defaults: UserDefaults
    private let key = "leaseaudit.disclaimer.acknowledged"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isAcknowledged: Bool {
        defaults.bool(forKey: key)
    }

    func acknowledge() {
        defaults.set(true, forKey: key)
    }
}
