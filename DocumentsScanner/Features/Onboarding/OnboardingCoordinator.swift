@MainActor
final class OnboardingCoordinator {
    var onFinish: () -> Void = {}

    func finish() {
        onFinish()
    }
}
