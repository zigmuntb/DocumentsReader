import SwiftUI

struct DSScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            DSColor.paper.ignoresSafeArea()
            content()
        }
    }
}
