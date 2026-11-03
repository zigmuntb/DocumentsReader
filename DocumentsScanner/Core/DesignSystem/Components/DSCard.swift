import SwiftUI

struct DSCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DSSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                DSColor.surface,
                in: RoundedRectangle(cornerRadius: DSRadius.l, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DSRadius.l, style: .continuous)
                    .strokeBorder(DSColor.hairline, lineWidth: 1)
            }
    }
}

#Preview {
    DSScreen {
        DSCard {
            Text(String(localized: "Parties, money, dates"))
                .font(DSFont.body)
                .foregroundStyle(DSColor.ink)
        }
        .padding(DSSpacing.l)
    }
}
