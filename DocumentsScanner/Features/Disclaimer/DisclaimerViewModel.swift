import Foundation
import Observation

@MainActor
@Observable
final class DisclaimerViewModel {
    var onAcknowledge: () -> Void = {}

    func acknowledge() {
        onAcknowledge()
    }
}
