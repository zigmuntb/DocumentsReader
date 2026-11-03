/// Preview and test double. The app launches with `UserDefaultsOnboardingStore`.
@MainActor
final class InMemoryOnboardingStore: OnboardingStoring {
    var isComplete: Bool

    init(isComplete: Bool = false) {
        self.isComplete = isComplete
    }

    func markComplete() {
        isComplete = true
    }
}
