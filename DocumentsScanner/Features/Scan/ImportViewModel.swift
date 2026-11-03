import Foundation
import Observation

@MainActor
@Observable
final class ImportViewModel {
    var onEvent: (ImportEvent) -> Void = { _ in }

    private let session: any DocumentSessionStoring

    init(session: any DocumentSessionStoring) {
        self.session = session
    }

    func receive(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            if Self.isCancellation(error) { return }
            onEvent(.failed)
        case .success(let urls):
            guard !urls.isEmpty else { return }
            do {
                let files = try urls.map { try ImportedFileStore.persist($0) }
                let id = session.stage(.pages(files.map { .file($0) }))
                onEvent(.ready(id))
            } catch {
                onEvent(.failed)
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }
}
