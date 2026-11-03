import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
final class ScriptedPurchases: PurchasesServicing {
    var hasPro: Bool
    var offerings: [LeaseOffering]
    var nextPurchase: PurchaseOutcome = .purchased
    var purchaseError: PurchaseFailure?
    var restoreError: PurchaseFailure?
    var grantsProOnRestore = true
    private(set) var purchasedKinds: [LeaseProductKind] = []

    init(hasPro: Bool = false, offerings: [LeaseOffering]? = nil) {
        self.hasPro = hasPro
        self.offerings = offerings ?? [
            LeaseOffering(kind: .yearly, displayPrice: "$29.99"),
            LeaseOffering(kind: .lifetime, displayPrice: "$49.99")
        ]
    }

    func refresh() async {}

    func loadOfferings() async throws -> [LeaseOffering] {
        if offerings.isEmpty { throw PurchaseFailure.productsUnavailable }
        return offerings
    }

    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome {
        if let purchaseError { throw purchaseError }
        purchasedKinds.append(kind)
        if nextPurchase == .purchased { hasPro = true }
        return nextPurchase
    }

    func restore() async throws {
        if let restoreError { throw restoreError }
        if grantsProOnRestore { hasPro = true }
    }
}
