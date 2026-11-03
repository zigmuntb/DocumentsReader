import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct OnboardingStoreTests {
    @Test func defaultsToIncompleteThenMarksComplete() {
        let suite = "OnboardingStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)
        #expect(defaults != nil)
        guard let defaults else { return }
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsOnboardingStore(defaults: defaults)
        #expect(store.isComplete == false)
        store.markComplete()
        #expect(store.isComplete)
    }
}
