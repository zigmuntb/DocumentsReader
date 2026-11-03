import Testing
@testable import DocumentsScanner

@MainActor
struct PlaceholderViewModelTests {
    @Test func actionCallsTheHandler() {
        let viewModel = PlaceholderViewModel(title: "Scan", message: "Message", actionTitle: "Close")
        var calls = 0
        viewModel.onAction = { calls += 1 }
        viewModel.performAction()
        #expect(calls == 1)
    }
}
