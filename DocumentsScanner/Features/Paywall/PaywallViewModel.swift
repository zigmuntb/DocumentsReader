import Foundation
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    var onEvent: (PaywallEvent) -> Void = { _ in }
    private(set) var phase: PaywallPhase = .loading
    private(set) var offerings: [LeaseOffering] = []
    private(set) var isPurchasing = false
    private(set) var notice: String?

    private let purchases: any PurchasesServicing

    init(purchases: any PurchasesServicing) {
        self.purchases = purchases
    }

    func load() async {
        if case .ready = phase, !offerings.isEmpty { return }
        phase = .loading
        notice = nil
        do {
            offerings = try await purchases.loadOfferings()
            phase = .ready
        } catch is CancellationError {
            return
        } catch let error as PurchaseFailure {
            phase = .failed(error)
        } catch {
            phase = .failed(.productsUnavailable)
        }
    }

    func buy(_ kind: LeaseProductKind) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        notice = nil
        defer { isPurchasing = false }
        do {
            switch try await purchases.purchase(kind) {
            case .purchased:
                onEvent(.purchased)
            case .cancelled:
                break
            case .pending:
                notice = String(localized: "The purchase is waiting for approval.")
            }
        } catch is CancellationError {
            return
        } catch let error as PurchaseFailure where error == .cancelled {
            return
        } catch let error as PurchaseFailure {
            notice = error.errorDescription
        } catch {
            notice = PurchaseFailure.failed.errorDescription
        }
    }

    func restore() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        notice = nil
        defer { isPurchasing = false }
        do {
            try await purchases.restore()
            if purchases.hasPro {
                onEvent(.purchased)
            } else {
                notice = String(localized: "No purchases to restore.")
            }
        } catch is CancellationError {
            return
        } catch let error as PurchaseFailure where error == .cancelled {
            return
        } catch let error as PurchaseFailure {
            notice = error.errorDescription
        } catch {
            notice = PurchaseFailure.failed.errorDescription
        }
    }

    func close() {
        onEvent(.closed)
    }
}
