import SwiftUI

extension ChecklistSeverity {
    var title: String {
        switch self {
        case .ok:
            String(localized: "Ordinary")
        case .check:
            String(localized: "Check this")
        }
    }

    var tint: Color {
        switch self {
        case .ok:
            DSColor.secondary
        case .check:
            DSColor.primary
        }
    }
}

struct ChecklistItemCard: View {
    let item: ChecklistItem

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.s) {
                Text(item.title)
                    .font(DSFont.title)
                    .foregroundStyle(DSColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.severity.title)
                    .font(DSFont.eyebrow)
                    .tracking(DSFont.eyebrowTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(item.severity.tint)
            }
            if !item.plainExplanation.isEmpty {
                Text(item.plainExplanation)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            DSQuoteBlock(text: item.quote)
        }
    }
}
