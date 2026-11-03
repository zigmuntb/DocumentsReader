import SwiftUI

struct LockedItemCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(String(localized: "Pro"))
                .font(DSFont.eyebrow)
                .tracking(DSFont.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundStyle(DSColor.primary)
            Text(String(localized: "Unlock this item"))
                .font(DSFont.title)
                .foregroundStyle(DSColor.ink)
            Text(String(localized: "The quote stays hidden until you unlock Pro."))
                .font(DSFont.body)
                .foregroundStyle(DSColor.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
