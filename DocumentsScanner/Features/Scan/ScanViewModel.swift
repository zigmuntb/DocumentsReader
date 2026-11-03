import Foundation
import Observation

@MainActor
@Observable
final class ScanViewModel {
    var onEvent: (ScanEvent) -> Void = { _ in }

    private let session: any DocumentSessionStoring

    init(session: any DocumentSessionStoring) {
        self.session = session
    }

    func didScan(pages: [Data]) {
        let images = pages.filter { !$0.isEmpty }
        guard !images.isEmpty else {
            onEvent(.failed)
            return
        }
        let id = session.stage(.pages(images.map { .image($0) }))
        onEvent(.finished(id))
    }

    func cancel() {
        onEvent(.cancelled)
    }
}
