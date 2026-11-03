import SwiftUI

/// Keeps the bar on the paper color and tells the system which status-bar style that color needs.
struct DSNavigationChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(DSColor.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
    }
}

extension View {
    func dsNavigationChrome() -> some View {
        modifier(DSNavigationChrome())
    }
}
