import Testing
@testable import DocumentsScanner

@MainActor
struct HomeViewModelTests {
    @Test func authorizedScanAndOtherTapsEmitEvents() async {
        let viewModel = HomeViewModel(
            camera: StubCameraAuthorizer(access: .authorized),
            settings: StubSettingsOpener()
        )
        var events: [HomeEvent] = []
        viewModel.onEvent = { events.append($0) }

        await viewModel.scanTapped()
        viewModel.importTapped()
        viewModel.historyTapped()
        viewModel.settingsTapped()

        #expect(events == [.scan, .importDocument, .history, .settings])
        #expect(viewModel.showsCameraDenied == false)
    }

    @Test func deniedCameraDoesNotOpenTheScanner() async {
        let viewModel = HomeViewModel(
            camera: StubCameraAuthorizer(access: .denied),
            settings: StubSettingsOpener()
        )
        var events: [HomeEvent] = []
        viewModel.onEvent = { events.append($0) }

        await viewModel.scanTapped()

        #expect(events.isEmpty)
        #expect(viewModel.showsCameraDenied)
    }

    @Test func openSettingsUsesTheOpener() {
        let opener = StubSettingsOpener()
        let viewModel = HomeViewModel(
            camera: StubCameraAuthorizer(access: .authorized),
            settings: opener
        )
        viewModel.openSettings()
        #expect(opener.opened)
    }
}

private struct StubCameraAuthorizer: CameraAuthorizing {
    let access: CameraAccess

    func resolveAccess() async -> CameraAccess {
        access
    }
}

@MainActor
private final class StubSettingsOpener: SettingsOpening {
    var opened = false

    func openAppSettings() {
        opened = true
    }
}
