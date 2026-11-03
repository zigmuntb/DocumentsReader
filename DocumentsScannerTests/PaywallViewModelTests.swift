import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct PaywallViewModelTests {
    @Test func loadShowsTheYearlyAndLifetimePlans() async {
        let model = PaywallViewModel(purchases: ScriptedPurchases())
        await model.load()
        #expect(model.phase == .ready)
        #expect(model.offerings.map(\.kind) == [.yearly, .lifetime])
    }

    @Test func aMissingCatalogFailsTheLoad() async {
        let model = PaywallViewModel(purchases: ScriptedPurchases(offerings: []))
        await model.load()
        #expect(model.phase == .failed(.productsUnavailable))
    }

    @Test func aPurchaseReportsSuccess() async {
        let purchases = ScriptedPurchases()
        let model = PaywallViewModel(purchases: purchases)
        var events: [PaywallEvent] = []
        model.onEvent = { events.append($0) }
        await model.buy(.yearly)
        #expect(events == [.purchased])
        #expect(purchases.purchasedKinds == [.yearly])
        #expect(purchases.hasPro)
        #expect(model.isPurchasing == false)
    }

    @Test func cancellingAPurchaseStaysQuiet() async {
        let purchases = ScriptedPurchases()
        purchases.nextPurchase = .cancelled
        let model = PaywallViewModel(purchases: purchases)
        var events: [PaywallEvent] = []
        model.onEvent = { events.append($0) }
        await model.buy(.lifetime)
        #expect(events.isEmpty)
        #expect(model.notice == nil)
        #expect(purchases.hasPro == false)
    }

    @Test func aFailedPurchaseShowsANotice() async {
        let purchases = ScriptedPurchases()
        purchases.purchaseError = .failed
        let model = PaywallViewModel(purchases: purchases)
        await model.buy(.yearly)
        #expect(model.notice == PurchaseFailure.failed.errorDescription)
        #expect(model.isPurchasing == false)
    }

    @Test func restoreWithoutAPurchaseExplainsThat() async {
        let purchases = ScriptedPurchases()
        purchases.grantsProOnRestore = false
        let model = PaywallViewModel(purchases: purchases)
        var events: [PaywallEvent] = []
        model.onEvent = { events.append($0) }
        await model.restore()
        #expect(events.isEmpty)
        #expect(model.notice == String(localized: "No purchases to restore."))
    }

    @Test func restoreWithProClosesAsAPurchase() async {
        let model = PaywallViewModel(purchases: ScriptedPurchases())
        var events: [PaywallEvent] = []
        model.onEvent = { events.append($0) }
        await model.restore()
        #expect(events == [.purchased])
    }

    @Test func closeEmitsClosed() {
        let model = PaywallViewModel(purchases: ScriptedPurchases())
        var events: [PaywallEvent] = []
        model.onEvent = { events.append($0) }
        model.close()
        #expect(events == [.closed])
    }
}
