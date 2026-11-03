import Foundation

enum HistoryState: Equatable {
    case empty
    case loaded([LeaseHistoryEntry])
    case failed
}
