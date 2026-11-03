import SwiftUI

struct OnboardingView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        DSScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.l) {
                    Text(String(localized: "Lease Audit"))
                        .font(DSFont.eyebrow)
                        .tracking(DSFont.eyebrowTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(DSColor.secondary)
                    Text(String(localized: "Read every line before you sign your lease."))
                        .font(DSFont.display)
                        .foregroundStyle(DSColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(String(localized: "Photograph a lease or import a PDF. Every checklist line stays tied to a quote from the document."))
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.inkSecondary)
                    DSButton(title: String(localized: "Continue"), style: .primary) {
                        viewModel.continueTapped()
                    }
                    .padding(.top, DSSpacing.m)
                }
                .padding(DSSpacing.l)
                .padding(.top, DSSpacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
