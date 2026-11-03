import Observation

@MainActor
@Observable
final class HomeViewModel {
    var onEvent: (HomeEvent) -> Void = { _ in }
    var showsCameraDenied = false

    private let camera: any CameraAuthorizing
    private let settings: any SettingsOpening

    init(
        camera: any CameraAuthorizing = SystemCameraAuthorizer(),
        settings: any SettingsOpening = SystemSettingsOpener()
    ) {
        self.camera = camera
        self.settings = settings
    }

    func scanTapped() async {
        let access = await camera.resolveAccess()
        switch access {
        case .authorized:
            onEvent(.scan)
        case .denied:
            showsCameraDenied = true
        }
    }

    func importTapped() {
        onEvent(.importDocument)
    }

    func historyTapped() {
        onEvent(.history)
    }

    func settingsTapped() {
        onEvent(.settings)
    }

    func openSettings() {
        settings.openAppSettings()
    }
}
