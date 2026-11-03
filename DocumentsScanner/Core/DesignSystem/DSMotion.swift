import SwiftUI

/// A short fade when one block of content replaces another.
/// Reduce Motion drops the fade. Pushes and sheets keep the system transition.
enum DSMotion {
    static let replace = Animation.easeOut(duration: 0.22)
}

extension View {
    func dsReplaces<Value: Equatable>(_ value: Value, reduceMotion: Bool) -> some View {
        animation(reduceMotion ? nil : DSMotion.replace, value: value)
    }
}
