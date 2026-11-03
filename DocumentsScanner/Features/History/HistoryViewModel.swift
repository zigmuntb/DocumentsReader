import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    var onEvent: (HistoryEvent) -> Void = { _ in }
    private(set) var state: HistoryState = .empty

    private let session: any DocumentSessionStoring

    init(session: any DocumentSessionStoring) {
        self.session = session
        reload()
    }

    func reload() {
        do {
            let entries = try session.history()
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch {
            state = .failed
        }
    }

    func select(_ entry: LeaseHistoryEntry) {
        onEvent(.open(entry.id))
    }
}
