import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var onEvent: (OnboardingEvent) -> Void = { _ in }

    func continueTapped() {
        onEvent(.continued)
    }
}
