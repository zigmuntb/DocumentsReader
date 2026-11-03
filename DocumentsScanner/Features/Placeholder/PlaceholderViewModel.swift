import Observation

@MainActor
@Observable
final class PlaceholderViewModel {
    let title: String
    let message: String
    let actionTitle: String
    var onAction: () -> Void = {}

    init(title: String, message: String, actionTitle: String) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
    }

    func performAction() {
        onAction()
    }
}
