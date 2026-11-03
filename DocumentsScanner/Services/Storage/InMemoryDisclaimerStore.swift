/// Preview and test double. The app launches with `UserDefaultsDisclaimerStore`.
@MainActor
final class InMemoryDisclaimerStore: DisclaimerStoring {
    var isAcknowledged: Bool

    init(isAcknowledged: Bool = false) {
        self.isAcknowledged = isAcknowledged
    }

    func acknowledge() {
        isAcknowledged = true
    }
}
