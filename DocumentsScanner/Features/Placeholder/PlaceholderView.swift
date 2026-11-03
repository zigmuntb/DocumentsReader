import SwiftUI

struct PlaceholderView: View {
    let viewModel: PlaceholderViewModel

    var body: some View {
        DSScreen {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                Text(viewModel.message)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSButton(title: viewModel.actionTitle, style: .primary) {
                    viewModel.performAction()
                }
                Spacer()
            }
            .padding(DSSpacing.l)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderView(
            viewModel: PlaceholderViewModel(
                title: "Scan",
                message: "The document camera is the next step. Pages stay on this device.",
                actionTitle: "Close"
            )
        )
    }
}
