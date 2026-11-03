import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct SettingsViewModelTests {
    @Test func proAndFreeFollowTheEntitlement() {
        let free = SettingsViewModel(purchases: ScriptedPurchases(hasPro: false))
        #expect(free.hasPro == false)
        let pro = SettingsViewModel(purchases: ScriptedPurchases(hasPro: true))
        #expect(pro.hasPro)
    }

    @Test func upgradeAsksForThePaywall() {
        let model = SettingsViewModel(purchases: ScriptedPurchases())
        var events: [SettingsEvent] = []
        model.onEvent = { events.append($0) }
        model.upgrade()
        #expect(events == [.showPaywall])
    }

    @Test func restoreWithoutAPurchaseExplainsThat() async {
        let purchases = ScriptedPurchases()
        purchases.grantsProOnRestore = false
        let model = SettingsViewModel(purchases: purchases)
        await model.restore()
        #expect(model.hasPro == false)
        #expect(model.notice == String(localized: "No purchases to restore."))
        #expect(model.isRestoring == false)
    }

    @Test func restoreGrantsPro() async {
        let model = SettingsViewModel(purchases: ScriptedPurchases())
        await model.restore()
        #expect(model.hasPro)
        #expect(model.notice == nil)
    }

    @Test func cancellingRestoreStaysQuiet() async {
        let purchases = ScriptedPurchases()
        purchases.restoreError = .cancelled
        let model = SettingsViewModel(purchases: purchases)
        await model.restore()
        #expect(model.notice == nil)
        #expect(model.hasPro == false)
    }

    @Test func aFailedRestoreShowsTheError() async {
        let purchases = ScriptedPurchases()
        purchases.restoreError = .failed
        let model = SettingsViewModel(purchases: purchases)
        await model.restore()
        #expect(model.notice == PurchaseFailure.failed.errorDescription)
    }
}
