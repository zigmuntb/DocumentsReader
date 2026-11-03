import Foundation
import StoreKit

/// StoreKit is the store. It never receives the lease text, and the app does not create an account.
@MainActor
final class StoreKitPurchaseService: PurchasesServicing {
    private(set) var hasPro = false

    private var cached: [LeaseProductKind: Product] = [:]
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            await self?.observeTransactions()
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func refresh() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verified(result) else { continue }
            guard Self.isPro(transaction.productID), transaction.revocationDate == nil else { continue }
            entitled = true
            break
        }
        hasPro = entitled
    }

    func loadOfferings() async throws -> [LeaseOffering] {
        let products: [Product]
        do {
            products = try await Product.products(for: Set(LeaseProductKind.allCases.map(\.productID)))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PurchaseFailure.productsUnavailable
        }
        var stored: [LeaseProductKind: Product] = [:]
        for product in products {
            if let kind = LeaseProductKind.allCases.first(where: { $0.productID == product.id }) {
                stored[kind] = product
            }
        }
        cached = stored
        let offerings = LeaseProductKind.allCases.compactMap { kind -> LeaseOffering? in
            guard let product = stored[kind] else { return nil }
            return LeaseOffering(kind: kind, displayPrice: product.displayPrice)
        }
        guard offerings.count == LeaseProductKind.allCases.count else {
            throw PurchaseFailure.productsUnavailable
        }
        return offerings
    }

    func purchase(_ kind: LeaseProductKind) async throws -> PurchaseOutcome {
        guard let product = cached[kind] else {
            throw PurchaseFailure.productsUnavailable
        }
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PurchaseFailure.failed
        }
        switch result {
        case .success(let verification):
            let transaction = try Self.verified(verification)
            await transaction.finish()
            await refresh()
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    func restore() async throws {
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            throw PurchaseFailure.cancelled
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PurchaseFailure.failed
        }
        await refresh()
    }

    private func observeTransactions() async {
        for await update in Transaction.updates {
            guard let transaction = try? Self.verified(update) else { continue }
            await transaction.finish()
            await refresh()
        }
    }

    private static func isPro(_ productID: String) -> Bool {
        LeaseProductKind.allCases.contains { $0.productID == productID }
    }

    private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseFailure.unverified
        }
    }
}
