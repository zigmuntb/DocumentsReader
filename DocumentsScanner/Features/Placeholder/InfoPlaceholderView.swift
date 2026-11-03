import SwiftUI

struct InfoPlaceholderView: View {
    let title: String
    let message: String

    var body: some View {
        DSScreen {
            VStack(alignment: .leading, spacing: DSSpacing.m) {
                Text(message)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(DSSpacing.l)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InfoPlaceholderView(
            title: "History",
            message: "Leases you audit will be kept on this device."
        )
    }
}
