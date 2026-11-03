import SwiftUI

struct DSQuoteBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DSFont.quote)
            .foregroundStyle(DSColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DSSpacing.m)
            .background(
                DSColor.quote,
                in: RoundedRectangle(cornerRadius: DSRadius.s, style: .continuous)
            )
            .accessibilityLabel(String(localized: "Quote from the lease"))
            .accessibilityValue(text)
    }
}

#Preview {
    DSScreen {
        DSQuoteBlock(text: "Tenant shall pay a late fee of $50 if rent is not received by the fifth.")
            .padding(DSSpacing.l)
    }
}
