import SwiftUI

@main
struct DocumentsScannerApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        let container = DependencyContainer()
        _coordinator = State(initialValue: container.makeAppCoordinator())
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
        }
    }
}
