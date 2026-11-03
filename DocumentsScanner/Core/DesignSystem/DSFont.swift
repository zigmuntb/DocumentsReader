import SwiftUI

/// System serif stands in for the editorial face on the design board.
/// TODO: swap in the named font files once the board labels are legible.
enum DSFont {
    static let display = Font.system(.largeTitle, design: .serif)
    static let title = Font.system(.title2, design: .serif)
    static let body = Font.system(.body, design: .serif)
    static let quote = Font.system(.callout, design: .serif).italic()
    static let label = Font.system(.subheadline, design: .default).weight(.semibold)
    static let eyebrow = Font.system(.caption, design: .default).weight(.semibold)
    static let eyebrowTracking: CGFloat = 0.8
}
