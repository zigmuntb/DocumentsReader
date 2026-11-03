@MainActor
final class PaywallCoordinator {
    var onClose: () -> Void = {}

    func close() {
        onClose()
    }
}
