import Foundation

enum ChecklistSeverity: Equatable, Sendable {
    case ok
    case check

    /// Anything other than an explicit "ok" stays on the side that asks for a second look.
    static func resolved(from raw: String) -> ChecklistSeverity {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "ok" ? .ok : .check
    }
}
