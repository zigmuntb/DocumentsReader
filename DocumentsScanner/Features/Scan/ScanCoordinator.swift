import Foundation

@MainActor
final class ScanCoordinator {
    var onFinish: (UUID) -> Void = { _ in }
    var onCancel: () -> Void = {}

    func finish(documentID: UUID) {
        onFinish(documentID)
    }

    func cancel() {
        onCancel()
    }
}
