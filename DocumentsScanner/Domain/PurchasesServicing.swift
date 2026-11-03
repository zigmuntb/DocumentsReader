import Foundation

/// Pro means an active yearly subscription or the lifetime purchase.
@MainActor
protocol PurchasesServicing: AnyObject {
    var hasPro: Bool { get }
    func refresh() async
    func loadOfferings() async throws -> [LeaseOffering]
    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome
    func restore() async throws
}
