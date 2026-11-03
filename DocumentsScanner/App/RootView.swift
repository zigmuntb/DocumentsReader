import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.root {
            case .onboarding:
                OnboardingView(viewModel: coordinator.onboardingViewModel)
            case .home:
                NavigationStack(path: $coordinator.path) {
                    HomeView(viewModel: coordinator.homeViewModel)
                        .navigationDestination(for: Route.self) { route in
                            coordinator.destination(for: route)
                        }
                }
                .dsNavigationChrome()
            }
        }
        .tint(DSColor.primary)
        .sheet(item: $coordinator.sheet) { sheet in
            coordinator.sheetContent(for: sheet)
        }
        .fullScreenCover(item: $coordinator.cover) { cover in
            coordinator.coverContent(for: cover)
        }
        .fileImporter(
            isPresented: $coordinator.isImporterPresented,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            coordinator.importViewModel.receive(result)
        }
        .alert(
            coordinator.notice?.title ?? "",
            isPresented: Binding(
                get: { coordinator.notice != nil },
                set: { isPresented in
                    if !isPresented {
                        coordinator.notice = nil
                    }
                }
            )
        ) {
            Button(String(localized: "Close"), role: .cancel) {}
        } message: {
            Text(coordinator.notice?.message ?? "")
        }
    }
}

#Preview("Onboarding") {
    RootView(
        coordinator: AppCoordinator(
            container: DependencyContainer(onboardingStore: InMemoryOnboardingStore())
        )
    )
}

#Preview("Home") {
    RootView(
        coordinator: AppCoordinator(
            container: DependencyContainer(onboardingStore: InMemoryOnboardingStore(isComplete: true))
        )
    )
}
