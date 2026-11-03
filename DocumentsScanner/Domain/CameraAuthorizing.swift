enum CameraAccess: Equatable, Sendable {
    case authorized
    case denied
}

protocol CameraAuthorizing: Sendable {
    func resolveAccess() async -> CameraAccess
}
