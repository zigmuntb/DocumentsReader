import SwiftUI

struct DisclaimerView: View {
    let viewModel: DisclaimerViewModel

    var body: some View {
        DSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    Text(String(localized: "Lease Audit reads the words on the page and quotes them. It does not tell you what the law requires, and it is not a lawyer. Read the lease yourself before you sign."))
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DSButton(title: String(localized: "I understand"), style: .primary) {
                        viewModel.acknowledge()
                    }
                }
                .padding(DSSpacing.l)
            }
        }
        .navigationTitle(String(localized: "Not legal advice"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DisclaimerView(viewModel: DisclaimerViewModel())
    }
}
