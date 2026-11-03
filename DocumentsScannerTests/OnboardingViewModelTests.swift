import Testing
@testable import DocumentsScanner

@MainActor
struct OnboardingViewModelTests {
    @Test func continueEmitsContinued() {
        let viewModel = OnboardingViewModel()
        var events: [OnboardingEvent] = []
        viewModel.onEvent = { events.append($0) }
        viewModel.continueTapped()
        #expect(events == [.continued])
    }
}
