import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var onEvent: (SettingsEvent) -> Void = { _ in }
    private(set) var hasPro = false
    private(set) var isRestoring = false
    private(set) var notice: String?

    private let purchases: any PurchasesServicing

    init(purchases: any PurchasesServicing) {
        self.purchases = purchases
        hasPro = purchases.hasPro
    }

    func refresh() async {
        await purchases.refresh()
        hasPro = purchases.hasPro
    }

    func applyCurrentAccess() {
        hasPro = purchases.hasPro
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        notice = nil
        defer { isRestoring = false }
        do {
            try await purchases.restore()
            hasPro = purchases.hasPro
            if !hasPro {
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

    func upgrade() {
        onEvent(.showPaywall)
    }
}
